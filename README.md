# Learn & Earn — Starter Scaffold

This is a minimal starter scaffold for the "Learn & Earn" app described in the provided brief.

What you'll find here:

- `pubspec.yaml` — minimal Flutter package manifest.
- `lib/main.dart` — tiny runnable Flutter app demonstrating activities and earnings placeholders.
- `firestore.rules` — starter Firestore security rules (v2) matching the data model in the brief.
- `remote_config_defaults.json` — initial Remote Config / `/config` defaults used by the app and Cloud Functions.
- `data_dictionary.md` — concise Firestore data model summary.

How to open

- Open this folder in VS Code or Android Studio.
- Run `flutter pub get` in the project folder and run the app on a device or emulator.

Next steps

- Wire Firebase (Auth / Firestore / Remote Config) and set up Cloud Functions.
- Implement the LP/AER calculation functions and admin console.
- Add tests and CI config.
