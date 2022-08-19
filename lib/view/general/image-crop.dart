import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class MyImageCropper{
  static Future<File?> cropImage(BuildContext context, File file) async {
    ImageCropper imgCrp = ImageCropper();
    CroppedFile? croppedFile = await imgCrp.cropImage(
      sourcePath: file.path,
      aspectRatioPresets: [CropAspectRatioPreset.square],
      cropStyle: CropStyle.circle,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          lockAspectRatio: true,
          toolbarTitle: '',
          toolbarWidgetColor: Color(0xFFFFFFFF),
          toolbarColor: Color(0xFF1D2343),
          hideBottomControls: true,
        )
      ]
    );
    if (croppedFile == null) return null;
    File cropped = File.fromUri(Uri.file(croppedFile.path));
    return cropped;
  }
}