# Contributing

Contributions to `mjn_liquid_ui` are welcome. The plugin combines Flutter,
SwiftUI, and UIKit, so changes should be tested at both the Dart and native iOS
boundaries when applicable.

## Before opening an issue

1. Search existing issues for the same behavior or request.
2. Reproduce the problem with the latest published package version or current
   `main` branch.
3. Reduce the problem to the smallest useful example.
4. Include Flutter, Xcode, iOS, and package versions for native issues.

Use the provided bug or feature form so reports contain the information needed
to act on them. Security vulnerabilities must follow [SECURITY.md](SECURITY.md)
and must not be reported publicly.

## Development setup

Requirements:

- Flutter compatible with the SDK constraints in `pubspec.yaml`.
- Xcode with an iOS simulator for native component changes.
- CocoaPods for the example iOS project.

Install dependencies:

```sh
flutter pub get
cd example
flutter pub get
cd ios
pod install
```

Run the example from the `example` directory:

```sh
flutter run -d <ios-simulator-id>
```

Changes under `ios/Classes` are not rebuilt by Flutter hot restart. Stop and
rerun the example so Xcode recompiles native Swift and SwiftUI code.

## Making changes

- Follow the existing API, naming, formatting, and platform-channel patterns.
- Keep changes focused; avoid unrelated refactors in the same pull request.
- Document new public Dart APIs with concise doc comments.
- Add or update tests for serialization, fallbacks, and changed behavior.
- Update the example when a user-facing component or workflow changes.
- Update `CHANGELOG.md` for user-visible fixes, features, or breaking changes.

## Validation

Run these checks from the repository root:

```sh
dart format lib test example/lib example/test
flutter analyze
flutter test
```

Then run the example tests:

```sh
cd example
flutter test
```

For native iOS changes, also verify a simulator build:

```sh
cd example
flutter build ios --simulator
```

## Pull requests

Explain what changed, why it is needed, and how it was validated. Include
screenshots or a short recording for visible UI changes. Keep commits readable
and make sure the pull request is free of generated build output and unrelated
local files.
