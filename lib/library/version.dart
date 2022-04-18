import 'package:brebit/api/system.dart';

class Version {
  static final String version = '1.0.0';

  static Future<bool> isLatest() async {
    String latestVersion = await SystemApi.getLatestVersion();
    return version == latestVersion;
  }
}
