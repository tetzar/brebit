import 'package:photo_manager/photo_manager.dart';

import 'habit_log.dart';
import 'model.dart';

class Draft extends Model {
  late String id;
  late String text;
  late List<AssetEntity>? imageAssets;
  HabitLog? log;

  static Future<Draft> fromJson(Map<String, dynamic> json) async {
    Draft draft = Draft();
    List<String> imageIds = json['image_ids'].cast<String>();
    List<AssetEntity> assets = <AssetEntity>[];
    for (String imageId in imageIds) {
      AssetEntity? asset = await AssetEntity.fromId(imageId);
      if (asset != null) {
        assets.add(asset);
      }
    }
    draft.imageAssets = assets;
    draft.text = json['text'];
    draft.id = json['id'];
    if (json['habit_log'] != null) {
      draft.log = HabitLog.fromJson(json['habit_log']);
    }
    return draft;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = <String, dynamic>{};
    List<String> imageIds = <String>[];
    (imageAssets ?? []).forEach((imageAsset) {
      imageIds.add(imageAsset.id);
    });
    data['image_ids'] = imageIds;
    data['text'] = text;
    data['id'] = id;
    data['habit_log'] = log != null ? log!.toJson() : null;
    return data;
  }
}
