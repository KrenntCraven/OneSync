# OneSync

Monorepo containing two Flutter applications:

- **OneSync (Customer)**: Customer-facing app.
- **OneSync (Vendor)**: Vendor-facing app.

## Requirements

- Flutter SDK (stable)
- Dart SDK (bundled with Flutter)
- Android Studio/Xcode (for mobile builds)

## Quick Start

Choose a project folder and run Flutter commands there.

### Customer App

```bash
cd "OneSync (Customer)"
flutter pub get
flutter run
```

### Vendor App

```bash
cd "OneSync (Vendor)"
flutter pub get
flutter run
```

## Project Structure

```
OneSync/
  OneSync (Customer)/
    lib/
    assets/
    android/
    ios/
    web/
    windows/
    macos/
    linux/
  OneSync (Vendor)/
    lib/
    assets/
    android/
    ios/
    web/
    windows/
    macos/
    linux/
```

## Architecture

High-level structure for both apps:

- **UI Layer**: Flutter widgets in `lib/screens/`.
- **Navigation**: Route setup in `lib/navigation.dart`.
- **Domain Models**: Data models in `lib/models/`.
- **Utilities**: Shared helpers in `lib/screens/utils.dart` (and other helper files).
- **Platform Targets**: Native wrappers under `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`.
- **ML Assets**: Local TensorFlow Lite model in `assets/` used by the app runtime.
- **Backend Services**: Firebase configuration and services per app.

```
Flutter UI (screens) → Navigation → Models/Utils
                  ↘ Firebase services ↙
```

## Technology

- **Flutter** (cross-platform UI)
- **Dart** (application language)
- **Firebase** (backend services per app)
- **TensorFlow Lite** (local inference via .tflite model)
- **Android Gradle** and **Xcode** build pipelines

## Firebase

Each app includes its own Firebase configuration:

- [OneSync (Customer)/firebase.json](OneSync%20(Customer)/firebase.json)
- [OneSync (Vendor)/firebase.json](OneSync%20(Vendor)/firebase.json)

## Assets

Machine learning model and sample CSV data live under each app’s assets folder.

## Testing

Run tests from the app folder:

```bash
flutter test
```

## Notes

- Use the app-specific README files for more detailed setup or platform notes.
- If you use separate Firebase projects per app, keep the configs in sync with those environments.
