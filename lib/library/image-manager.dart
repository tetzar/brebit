import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

class ImageManager {
  static Future<File> assetEntityToFile(AssetEntity asset) async{
    File file = await asset.file;
    while(!file.isAbsolute) file = file.absolute;
    return file;
  }

  static Future<List<File>> assetEntitiesToFiles(List<AssetEntity> assets) async {
    List<File> files = [];
    for (AssetEntity asset in assets) files.add(await assetEntityToFile(asset));
    return files;
  }
}