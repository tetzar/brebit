import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

class ImageManager {
  static Future<File?> assetEntityToFile(AssetEntity asset) async {
    File? file = await asset.file;
    if (file == null) return null;
    while (!file!.isAbsolute) file = file.absolute;
    return file;
  }

  static Future<List<File>> assetEntitiesToFiles(
      List<AssetEntity> assets) async {
    List<File> files = [];
    for (AssetEntity asset in assets) {
      File? file = await assetEntityToFile(asset);
      if (file != null) {
        files.add(file);
      }
    }
    return files;
  }
}
