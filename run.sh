#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [ "$#" -gt 1 ]; then
  echo "Usage: bash run.sh [iPhone simulator UUID]" >&2
  exit 2
fi

app_path="$PWD/build/Products/Debug-iphonesimulator/SimpleNote.app"
if [ ! -d "$app_path" ]; then
  echo "App build not found. Run bash build.sh first." >&2
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
print("Using " + device["name"] + " (iOS " + ".".join(map(str, version))
      + "), " + device["udid"], file=sys.stderr)
print(device["udid"])
' "$requested_id")"

xcrun simctl bootstatus "$simulator_id" -b
open -a Simulator --args -CurrentDeviceUDID "$simulator_id"
xcrun simctl install "$simulator_id" "$app_path"
xcrun simctl launch "$simulator_id" org.example.iOSSample
