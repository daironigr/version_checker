import 'package:flutter_test/flutter_test.dart';

import 'package:version_checker/version_checker.dart';

void main() {
  test('adds one to input values', () async {
    final versionChecker = VersionChecker();

    print(await versionChecker.getVersionStatus());
  });
}
