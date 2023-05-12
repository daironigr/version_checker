class VersionStatus {
  final String localVersion;
  final String storeVersion;
  final String storeLink;
  final String? releaseNotes;

  VersionStatus(
      {required this.localVersion,
      required this.storeVersion,
      required this.storeLink,
      this.releaseNotes});

  bool get canUpdate {
    final local = localVersion.split('.').map(int.parse).toList();
    final store = storeVersion.split('.').map(int.parse).toList();

    for (var i = 0; i < local.length; i++) {
      if (local[i] < store[i]) {
        return true;
      }
      if (local[i] > store[i]) {
        return false;
      }
    }
    return false;
  }
}
