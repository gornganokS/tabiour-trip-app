# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Local Google Maps configuration

API keys are excluded from Git. Before running the mobile app:

- Android: add `GOOGLE_MAPS_API_KEY=your_android_key` to `android/local.properties`.
- iOS: create `ios/Flutter/MapsSecrets.xcconfig` with `GOOGLE_MAPS_API_KEY = your_ios_key`.
- Restrict each key to its mobile application in Google Cloud.
- Pass the reachable backend URL using `flutter run --dart-define=API_BASE_URL=https://your-api-host`.

The backend requires its own local `.env` configuration and database. Uploaded avatars are not included in this repository.
