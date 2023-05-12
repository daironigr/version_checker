import 'package:flutter_test/flutter_test.dart';
import 'package:version_checker/version_status.dart';

void main() {
  test('compare versions', () async {
    final versionStatus = VersionStatus(
        localVersion: "1.3.0", storeVersion: "1.2.2", storeLink: "");

    expect(versionStatus, false);
  });
}
