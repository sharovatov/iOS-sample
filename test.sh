#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [ "$#" -gt 1 ]; then
  echo "Usage: bash test.sh [iPhone simulator UUID]" >&2
  exit 2
fi

app_path="$PWD/build/Products/Debug-iphonesimulator/SimpleNote.app"
unit_test_bundle_path="$app_path/PlugIns/SimpleNoteTests.xctest"
ui_test_bundle_path="$PWD/build/Products/Debug-iphonesimulator/SimpleNoteUITests-Runner.app/PlugIns/SimpleNoteUITests.xctest"
if [ ! -d "$unit_test_bundle_path" ] || [ ! -d "$ui_test_bundle_path" ]; then
  echo "Test build not found. Run bash build.sh first." >&2
  exit 1
fi

requested_id="${1:-${SIMULATOR_ID:-}}"
simulator_id="$(xcrun simctl list devices available --json | python3 -c '
import json
import sys

requested = sys.argv[1]
candidates = []
for runtime, devices in json.load(sys.stdin)["devices"].items():
    prefix = "com.apple.CoreSimulator.SimRuntime.iOS-"
    if not runtime.startswith(prefix):
        continue
    version = tuple(int(part) for part in runtime[len(prefix):].split("-"))
    if version < (18, 0):
        continue
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            candidates.append((version, device))

if requested:
    candidates = [(version, device) for version, device in candidates
                  if device["udid"] == requested]
if not candidates:
    message = ("No available iPhone simulator matches " + requested + "."
               if requested else "No available iPhone simulator with iOS 18 or newer.")
    sys.exit(message + " Run: xcrun simctl list devices available")

version, device = max(candidates, key=lambda item:
                      (item[1]["state"] == "Booted", item[0]))
print(device["udid"])
' "$requested_id")"

log_path="$PWD/build/test.log"
if ! xcrun simctl bootstatus "$simulator_id" -b > "$log_path" 2>&1; then
  cat "$log_path" >&2
  exit 1
fi

for test_target in SimpleNoteTests SimpleNoteUITests; do
  case "$test_target" in
    SimpleNoteTests) printf 'Unit tests\n' ;;
    SimpleNoteUITests) printf '\nUI tests\n' ;;
  esac
  log_offset="$(wc -c < "$log_path")"
  test_status=0
  xcodebuild test-without-building -xctestrun SimpleNote.xctestrun \
    -destination "platform=iOS Simulator,id=$simulator_id,arch=arm64" \
    "-only-testing:$test_target" \
    -parallel-testing-enabled NO >> "$log_path" 2>&1 || test_status=$?

  python3 - "$log_path" "$test_status" "$log_offset" "$test_target" <<'PY'
from pathlib import Path
import re
import sys

log_path = Path(sys.argv[1])
status = int(sys.argv[2])
with log_path.open("rb") as log_file:
    log_file.seek(int(sys.argv[3]))
    log = log_file.read().decode(errors="replace")
target = sys.argv[4]
results = re.findall(r"^Test Case '(.+)' (passed|failed|skipped)\b", log, re.MULTILINE)

for name, outcome in results:
    match = re.fullmatch(r"-\[(\S+) (.+)\]", name)
    if match:
        suite, method = match.groups()
        name = suite.rsplit(".", 1)[-1] + "." + method
    label = "success" if outcome == "passed" else outcome
    print(f"  {name} - {label}")

if status or any(outcome == "failed" for _, outcome in results):
    print(f"{target} failed. Full log: {log_path}", file=sys.stderr)
    sys.exit(status or 1)
if not results:
    print(f"No test results found for {target}. Full log: {log_path}", file=sys.stderr)
    sys.exit(1)
PY
done

printf '\ndone\n'
