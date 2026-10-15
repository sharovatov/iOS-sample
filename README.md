# Simple Note

A native iPhone app with one editable note and a Save button. Editing changes the draft; only Save replaces the local UTF-8 file. Relaunching restores the last saved text, or an empty editor before the first save. Unsaved edits are discarded when the process ends. Storage failures appear in an alert.

## Setup

Requires Xcode, Apple silicon, and an installed iOS simulator runtime (iOS 18.0 or newer) for the command-line steps below. There are no external dependencies or account requirements for simulator use. Run the commands from this directory.

In Xcode, open `SimpleNote.xcodeproj`, select the **SimpleNote** scheme and an iPhone simulator, and choose **Product > Run** or **Product > Test**. Xcode may require its matching platform component in **Settings > Components** before it offers run destinations. The command-line route below can use an older installed runtime without that download.

## Build

```sh
bash build.sh
```

This builds the app, unit tests and UI test runner into the ignored `build/` directory. No simulator selection is needed for the build. The supplied `SimpleNote.xctestrun` points to these build products and uses Xcode's standard test runner.

## Run

```sh
bash run.sh
```

The script selects an available iPhone with iOS 18 or newer, preferring an already booted device, then the newest installed runtime. It boots the device if needed, opens Simulator, installs the app and launches it. Device selection uses Python 3, available with the Xcode command-line tools. Both scripts work when invoked separately and from any working directory.

To choose a particular simulator, list the devices and pass its UUID:

```sh
xcrun simctl list devices available
bash run.sh YOUR_SIMULATOR_UUID
```

Replace `YOUR_SIMULATOR_UUID` with an actual UUID from the list. An exported `SIMULATOR_ID` is also accepted; a command-line UUID takes precedence.

To check unsaved changes manually: save `A`, replace it with `B` without saving, terminate the app, and launch it again. `A` returns. Saving `B` before the same restart restores `B`. Use the UUID printed by `run.sh`:

```sh
SIMULATOR_ID='YOUR_SIMULATOR_UUID'
xcrun simctl terminate "$SIMULATOR_ID" org.example.iOSSample
xcrun simctl launch "$SIMULATOR_ID" org.example.iOSSample
```

## Tests

Build with `bash build.sh`, then run the tests:

```sh
bash test.sh
```

The script runs `SimpleNoteTests` first, then `SimpleNoteUITests` only if the unit test run succeeds. A failing unit test or runner error stops the script before any UI tests start. It selects and boots an iPhone simulator using the same rules as `run.sh`, and works from any working directory. An optional UUID or exported `SIMULATOR_ID` selects a particular simulator; the command-line UUID takes precedence:

```sh
bash test.sh YOUR_SIMULATOR_UUID
```

Tests use the existing build products, so rerun `bash build.sh` after changing app or test code.

Successful output groups tests by category, followed by `done`:

```text
Unit tests
  NoteModelTests.testEditingDraftLeavesSavedNoteUnchanged - success

UI tests
  NotePersistenceTests.testSavedNoteSurvivesProcessRelaunch - success

done
```

Full simulator boot and XCTest output is saved to `build/test.log`, replaced on each run. Failed and skipped tests are labeled accordingly. A failed test or test run exits with a nonzero status and does not print `done`.

To run only unit tests directly, select an available iPhone UUID and run:

```sh
SIMULATOR_ID='YOUR_SIMULATOR_UUID'
xcodebuild test-without-building -xctestrun SimpleNote.xctestrun \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=arm64" \
  -only-testing:SimpleNoteTests \
  -parallel-testing-enabled NO
```

Replace `SimpleNoteTests` with `SimpleNoteUITests` to run only UI tests.

Set `SIMULATOR_ID` in the same shell or test script as the command that uses it. Variables assigned inside `bash build.sh` do not carry into a later `bash run.sh` or another script.

- `NoteModelTests.testEditingDraftLeavesSavedNoteUnchanged`: uses an isolated temporary file and the app's actual model/storage. Checks an empty first draft, explicit saving, and that later edits leave the saved value unchanged.
- `NotePersistenceTests.testSavedNoteSurvivesProcessRelaunch`: types a unique marker through the UI, saves, terminates the process, launches the same app again, and checks the entire saved text. It does not uninstall the app, clear storage, or inject a persistence substitute between launches. Repeated runs add a marker to the test app's note.

With matching Xcode platform support installed, the shared scheme also supports the usual `xcodebuild -project SimpleNote.xcodeproj -scheme SimpleNote -destination "platform=iOS Simulator,id=$SIMULATOR_ID" -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test` workflow.

The app stores `note.txt` in its sandbox's Application Support directory. It uses an atomic, synchronous file write on Save. It has no autosave, network service, or multiple-note workflow.
