<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->


## Overview
Original repository: https://pub.dev/packages/new_version_plus

This package allow to check available updates in respective stores, so it supports
AppStore, PlayStore and AppGallery

The main difference between this and original package is that original does not support
AppGallery version checking

## Getting started

# What Version Checker do

A Flutter plugin that makes it possible to:
* Check if a user has the most recent version of your app installed.

## Installation
Add new_version_plus as [a dependency in your `pubspec.yaml` file.](https://flutter.io/using-packages/)
```
dependencies:
  new_version_plus: ^0.0.9
```

## Usage

In `main.dart` (or wherever your app is initialized), create an instance of `VersionChecker`.

`final versionChecker = VersionChecker();`

The plugin will automatically use your Flutter package identifier to check the app store. If your app has a different identifier in the Google Play Store or Apple App Store, you can overwrite this by providing values for `androidId` and/or `iOSId`. If you need to check AppGallery, you must set `checkAppGallery` to `true` and provide `appGalleryId`, `appGalleryClientId` and `appGalleryClientSecret`:

```dart
VersionChecker versionChecker = VersionChecker(
      checkAppGallery: true
      appGalleryId: "<your app ID>",
      appGalleryClientId: "<yout app gallery client ID>",
      appGalleryClientSecret:
          "<yout app gallery client secret ID>",
    );

VersionStatus status = await versionChecker.getVersionStatus();

print(value!.localVersion);
print(value!.storeVersion);
print(value!.canUpdate);
print(value!.storeLink);
```

*For iOS:* If your app is only available outside the U.S. App Store, you will need to set `iOSAppStoreCountry` to the two-letter country code of the store you want to search. See http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 for a list of ISO Country Codes.

<script type="text/javascript" src="https://cdnjs.buymeacoffee.com/1.0.0/button.prod.min.js" data-name="bmc-button" data-slug="daironigr" data-color="#5F7FFF" data-emoji=""  data-font="Cookie" data-text="Buy me a coffee" data-outline-color="#000000" data-font-color="#ffffff" data-coffee-color="#FFDD00" ></script>
