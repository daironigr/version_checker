library version_checker;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huawei_hmsavailability/huawei_hmsavailability.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version_checker/version_status.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class VersionChecker {
  /// An optional value that can override the default packageName when
  /// attempting to reach the Apple App Store. This is useful if your app has
  /// a different package name in the App Store.
  final String? iOSId;

  /// An optional value that can override the default packageName when
  /// attempting to reach the Google Play Store. This is useful if your app has
  /// a different package name in the Play Store.
  final String? androidId;

  /// This value is required if your app is available on AppGallery. You can get
  /// this value in App Information at your AppGallery Connect with label "App ID"
  final String? appGalleryId;

  /// Only affects iOS App Store lookup: The two-letter country code for the store you want to search.
  /// Provide a value here if your app is only available outside the US.
  /// For example: US. The default is US.
  /// See http://en.wikipedia.org/wiki/ ISO_3166-1_alpha-2 for a list of ISO Country Codes.
  final String? iOSAppStoreCountry;

  /// Only affects Android Play Store lookup: The two-letter country code for the store you want to search.
  /// Provide a value here if your app is only available outside the US.
  /// For example: US. The default is US.
  /// See http://en.wikipedia.org/wiki/ ISO_3166-1_alpha-2 for a list of ISO Country Codes.
  /// see https://www.ibm.com/docs/en/radfws/9.6.1?topic=overview-locales-code-pages-supported
  final String? androidPlayStoreCountry;

  /// This value is required if your app is available on AppGallery.
  /// See https://developer.huawei.com/consumer/en/doc/development/AppGallery-connect-Guides/agcapi-getstarted-0000001111845114#section103mcpsimp
  final String? appGalleryClientId;

  /// This value is required if your app is available on AppGallery.
  /// See https://developer.huawei.com/consumer/en/doc/development/AppGallery-connect-References/agcapi-obtain_token-0000001158365043
  final String? appGalleryClientSecret;

  /// Defaults to "false", if you need to check your App version against AppGallery
  /// set this value to true and provide `appGalleryId`, `appGalleryClientId`
  /// and `appGalleryClientSecret`
  final bool checkAppGallery;

  VersionChecker(
      {this.iOSId,
      this.androidId,
      this.appGalleryId,
      this.iOSAppStoreCountry,
      this.androidPlayStoreCountry,
      this.appGalleryClientId,
      this.appGalleryClientSecret,
      this.checkAppGallery = false});

  /// This checks the version status and returns the information. This is useful
  /// if you want to display a custom alert, or use the information in a different
  /// way.
  Future<VersionStatus?> getVersionStatus() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    HmsApiAvailability client = HmsApiAvailability();

    if (Platform.isIOS) {
      return _getiOSStoreVersion(packageInfo);
    } else if (checkAppGallery && await client.isHMSAvailable() != 1) {
      return _getAppGalleryVersion(packageInfo);
    } else if (Platform.isAndroid) {
      return _getPlayStoreVersion(packageInfo);
    } else {
      debugPrint(
          'The target platform "${Platform.operatingSystem}" is not yet supported by this package.');
      return null;
    }
  }

  String _getCleanVersion(String version) =>
      RegExp(r'\d+\.\d+(\.\d+)?').stringMatch(version) ?? '0.0.0';

  Future<VersionStatus?> _getiOSStoreVersion(PackageInfo packageInfo) async {
    final id = iOSId ?? packageInfo.packageName;
    final parameters = {"bundleId": id};
    if (iOSAppStoreCountry != null) {
      parameters.addAll({"country": iOSAppStoreCountry!});
    }
    var uri = Uri.https("itunes.apple.com", "/lookup", parameters);
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      debugPrint('Failed to query iOS App Store');
      return null;
    }
    final jsonObj = json.decode(response.body);
    final List results = jsonObj['results'];
    if (results.isEmpty) {
      debugPrint('Can\'t find an app in the App Store with the id: $id');
      return null;
    }
    return VersionStatus(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion: _getCleanVersion(jsonObj['results'][0]['version']),
      storeLink: jsonObj['results'][0]['trackViewUrl'],
      releaseNotes: jsonObj['results'][0]['releaseNotes'],
    );
  }

  Future<VersionStatus?> _getPlayStoreVersion(PackageInfo packageInfo) async {
    final id = androidId ?? packageInfo.packageName;
    final uri = Uri.https("play.google.com", "/store/apps/details",
        {"id": id.toString(), "hl": androidPlayStoreCountry ?? "en_US"});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception("Invalid response code: ${response.statusCode}");
    }
    // Supports 1.2.3 (most of the apps) and 1.2.prod.3 (e.g. Google Cloud)
    //final regexp = RegExp(r'\[\[\["(\d+\.\d+(\.[a-z]+)?\.\d+)"\]\]');
    final regexp =
        RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
    final storeVersion = regexp.firstMatch(response.body)?.group(1);

    //Description
    //final regexpDescription = RegExp(r'\[\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');

    //Release
    final regexpRelease =
        RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');

    final expRemoveSc = RegExp(r"\\u003c[A-Za-z]{1,10}\\u003e",
        multiLine: true, caseSensitive: true);

    final releaseNotes = regexpRelease.firstMatch(response.body)?.group(3);
    //final descriptionNotes = regexpDescription.firstMatch(response.body)?.group(2);

    return VersionStatus(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion: _getCleanVersion(storeVersion ?? ""),
      storeLink: uri.toString(),
      releaseNotes: releaseNotes?.replaceAll(expRemoveSc, ''),
    );
  }

  Future<VersionStatus?> _getAppGalleryVersion(PackageInfo packageInfo) async {
    if (appGalleryId == null ||
        appGalleryClientId == null ||
        appGalleryClientSecret == null) {
      throw Exception(
          "You must provide 'appGalleryId', 'appGalleryClientId' and 'appGalleryClientSecret' together");
    }

    String? token = await _fetchAppGalleryToken();

    Map<String, String> security = {
      "client_id": appGalleryClientId!,
      "Authorization": "Bearer $token"
    };
    Uri url = Uri.https("connect-api.cloud.huawei.com",
        "/api/publish/v2/app-info", {"appId": appGalleryId});

    var response = await http.get(url, headers: security);

    if (response.statusCode != 200) {
      throw Exception("Invalid response code: ${response.statusCode}");
    }

    var body = jsonDecode(response.body);
    var appInfo = body['appInfo'];
    String storeVersion = appInfo['versionNumber'];
    Uri storeLink = Uri.https("appgallery.huawei.com", "/app/C$appGalleryId");

    /// The Apps in AppGallery have an attribute called releaseState that
    /// indicates the release state of the app, in this case we expect it to be 0,
    /// which indicates that it has been released successfully
    /// Refers to: https://developer.huawei.com/consumer/en/doc/development/AppGallery-connect-References/agcapi-app-info-query-0000001158365045
    if (body['releaseState'] != 0) {
      return VersionStatus(
        localVersion: _getCleanVersion(packageInfo.version),
        storeVersion: _getCleanVersion(packageInfo.version),
        storeLink: storeLink.toString(),
      );
    }
    return VersionStatus(
      localVersion: _getCleanVersion(packageInfo.version),
      storeVersion: _getCleanVersion(storeVersion),
      storeLink: storeLink.toString(),
    );
  }

  Future<String?> _fetchAppGalleryToken() async {
    final uri =
        Uri.https("connect-api.cloud.huawei.com", "/api/oauth2/v1/token");

    final response = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "grant_type": "client_credentials",
          "client_id": appGalleryClientId,
          "client_secret": appGalleryClientSecret
        }));

    if (response.statusCode != 200) {
      throw Exception("Invalid response code: ${response.statusCode}");
    }
    if (response.body != null) {
      return jsonDecode(response.body)['access_token'];
    }

    return null;
  }
}
