import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as Img;
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';

import 'model.dart';

// ignore: non_constant_identifier_names
List<Image> imageFromJson(List<dynamic> decodedList) => List<Image>.from(
    decodedList.cast<Map<String, dynamic>>().map((x) => Image.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> imageToJson(List<Image> data) =>
    new List<Map>.from(data.map((x) => x.toJson()));

class Image extends Model {
  int id;
  int imageableId;
  int url;
  String imageableType;
  DateTime createdAt;
  DateTime updatedAt;

  Image({
    required this.id,
    required this.imageableId,
    required this.url,
    required this.imageableType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Image.fromJson(Map<String, dynamic> json) => new Image(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        id: json["id"],
        imageableId: json["imageable_id"],
        url: json["url"],
        imageableType: json["imageable_type"],
      );

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "id": id,
        "imageable_id": imageableId,
        "url": url,
        "imageable_type": imageableType,
      };

  static Future<File> resizeImage(File file, {int? sizeLessThen}) async {
    if (sizeLessThen == null) {
      sizeLessThen = (2 * pow(1024, 2)).toInt();
    }
    int num = Random().nextInt(500000);
    final tempDir = await getApplicationDocumentsDirectory();
    Img.Image? image = Img.decodeImage(file.readAsBytesSync());
    if (image == null) return file;
    if (!ImageSizeGetter.isJpg(FileInput(file))) {
      file = new File(tempDir.path + '/$num.jpg')
        ..writeAsBytesSync(Img.encodeJpg(image));
    }
    while (file.lengthSync() > sizeLessThen) {
      Size size = ImageSizeGetter.getSize(FileInput(file));
      image = Img.copyResize(image!, height: (size.height ~/ 2));
      file = new File(tempDir.path + '/$num.jpg')
        ..writeAsBytesSync(Img.encodeJpg(image));
    }
    return file;
  }
}
