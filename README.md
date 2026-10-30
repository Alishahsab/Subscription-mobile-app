# Premium Store Admin

Android and iOS app for the Premium Store admin team. It is built with Flutter (Dart).

## Requirements

- Flutter 3.41 or newer (`flutter --version`)
- Android Studio with an Android SDK, or a phone with USB debugging turned on

## Run the app

```bash
flutter pub get
flutter run
```

In Android Studio: open this folder, pick a device at the top, then press Run.

## Project structure

```
lib/
  main.dart              starts the app
  app.dart               app setup (name, theme, first screen)
  core/
    config/              Supabase project and website links
    constants/           app name, asset paths
    theme/               colours and theme, same as the website
  features/
    auth/                sign in, sign out, admin check
    home/                floating bottom tabs
    splash/              animated splash screen
    panel/               the admin panel (website) inside the app
assets/
  icon/                  source images for the app icon
  images/                images used inside the app
docs/
  progress.md            what was done each day
```

New screens go in `lib/features/<feature name>/`. Shared code goes in `lib/core/`.

## App icon

The icon images are in `assets/icon`. After changing them, run:

```bash
dart run flutter_launcher_icons
```

## Splash screen

Settings are under `flutter_native_splash` in `pubspec.yaml`. After changing them, run:

```bash
dart run flutter_native_splash:create
```

## Checks before pushing

```bash
flutter analyze
flutter test
```
