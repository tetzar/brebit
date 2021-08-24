import 'dart:io';
import 'dart:math';

import 'model.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Img;

// ignore: non_constant_identifier_names
List<Image> ImageFromJson(List<dynamic> decodedList) =>
    List<Image>.from(decodedList.cast<Map>().map((x) => Image.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> ImageToJson(List<Image> data) =>
    new List<dynamic>.from(data.map((x) => x.toJson()));

class Image extends Model {
  int id;
  int imageableId;
  int url;
  String imageableType;
  DateTime createdAt;
  DateTime updatedAt;

  Image({
    this.id,
    this.imageableId,
    this.url,
    this.imageableType,
    this.createdAt,
    this.updatedAt,
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

  static Future<File> resizeImage(File file, {int sizeLessThen}) async {
    if (sizeLessThen == null) {
      sizeLessThen = (2 * pow(1024, 2));
    }
    int num = Random().nextInt(500000);
    final tempDir = await getApplicationDocumentsDirectory();
    Img.Image image = Img.decodeImage(file.readAsBytesSync());
    if ( ! ImageSizeGetter.isJpg(FileInput(file))) {
      file = new File(tempDir.path + '/$num.jpg')
        ..writeAsBytesSync(Img.encodeJpg(image));
    }
    while (file.lengthSync() > sizeLessThen) {
      Size size = ImageSizeGetter.getSize(FileInput(file));
      image = Img.copyResize(image, height: (size.height ~/ 2));
      file = new File(tempDir.path + '/$num.jpg')
        ..writeAsBytesSync(Img.encodeJpg(image));
    }
    return file;
  }
}
