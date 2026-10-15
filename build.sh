#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

xcodebuild -project SimpleNote.xcodeproj -alltargets \
  -configuration Debug -sdk iphonesimulator ARCHS=arm64 \
  SYMROOT="$PWD/build/Products" OBJROOT="$PWD/build/Intermediates" \
  -disableAutomaticPackageResolution -skipPackageUpdates \
  CODE_SIGNING_ALLOWED=NO build
