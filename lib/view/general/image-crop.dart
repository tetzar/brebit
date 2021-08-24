import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class MyImageCropper{
  static Future<File> cropImage(BuildContext context, File file) async {
    File croppedImage = await ImageCropper.cropImage(
      sourcePath: file.path,
      aspectRatioPresets: [CropAspectRatioPreset.square],
      cropStyle: CropStyle.circle,
      compressFormat: ImageCompressFormat.jpg,
      androidUiSettings: AndroidUiSettings(
        lockAspectRatio: true,
        toolbarTitle: '',
        toolbarWidgetColor: Color(0xFFFFFFFF),
        toolbarColor: Color(0xFF1D2343),
        hideBottomControls: true,

      )
    );
    return croppedImage;
  }
}