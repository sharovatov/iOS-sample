# Simple Note

A native iPhone app with one editable note and a Save button. Editing changes the draft; only Save replaces the local UTF-8 file. Relaunching restores the last saved text, or an empty editor before the first save. Unsaved edits are discarded when the process ends. Storage failures appear in an alert.

## Setup

Requires Xcode, Apple silicon, and an installed iOS simulator runtime (iOS 18.0 or newer) for the command-line steps below. There are no external dependencies or account requirements for simulator use. Run the commands from this directory.

In Xcode, open `SimpleNote.xcodeproj`, select the **SimpleNote** scheme and an iPhone simulator, and choose **Product > Run** or **Product > Test**. Xcode may require its matching platform component in **Settings > Components** before it offers run destinations. The command-line route below can use an older installed runtime without that download.

## Build

```sh
xcrun simctl list devices available
SIMULATOR_ID='<chosen iPhone simulator UUID>'
xcodebuild -project SimpleNote.xcodeproj -alltargets \
  -configuration Debug -sdk iphonesimulator ARCHS=arm64 \
  SYMROOT="$PWD/build/Products" OBJROOT="$PWD/build/Intermediates" \
  -disableAutomaticPackageResolution -skipPackageUpdates \
  CODE_SIGNING_ALLOWED=NO build
```

This builds the app, unit tests and UI test runner. The supplied `SimpleNote.xctestrun` points to these build products and uses Xcode's standard test runner. It contains no simulator identifier or machine-specific absolute paths.

## Run

```sh
xcrun simctl boot "$SIMULATOR_ID" # Only if the device is shut down.
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl install "$SIMULATOR_ID" build/Products/Debug-iphonesimulator/SimpleNote.app
xcrun simctl launch "$SIMULATOR_ID" org.example.iOSSample
```

Open Simulator to interact with the running app. To check unsaved changes manually: save `A`, replace it with `B` without saving, terminate the process with the following command, then launch it again. `A` returns. Saving `B` before the same restart restores `B`.

```sh
xcrun simctl terminate "$SIMULATOR_ID" org.example.iOSSample
xcrun simctl launch "$SIMULATOR_ID" org.example.iOSSample
```

## Tests

After building, run:

```sh
xcodebuild test-without-building -xctestrun SimpleNote.xctestrun \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=arm64" \
  -parallel-testing-enabled NO
```

- `NoteModelTests.testEditingDraftLeavesSavedNoteUnchanged`: uses an isolated temporary file and the app's actual model/storage. Checks an empty first draft, explicit saving, and that later edits leave the saved value unchanged.
- `NotePersistenceTests.testSavedNoteSurvivesProcessRelaunch`: types a unique marker through the UI, saves, terminates the process, launches the same app again, and checks the entire saved text. It does not uninstall the app, clear storage, or inject a persistence substitute between launches. Repeated runs add a marker to the test app's note.

With matching Xcode platform support installed, the shared scheme also supports the usual `xcodebuild -project SimpleNote.xcodeproj -scheme SimpleNote -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test` workflow.

The app stores `note.txt` in its sandbox's Application Support directory. It uses an atomic, synchronous file write on Save. It has no autosave, network service, or multiple-note workflow.
