
import 'model.dart';

// ignore: non_constant_identifier_names
List<StrategyReview> StrategyReviewFromJson(List<dynamic> decodedList) =>
    new List<StrategyReview>.from(
        decodedList.cast<Map>().map((x) => StrategyReview.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> StrategyReviewToJson(List<StrategyReview> data) =>
    new List<Map>.from(data.map((x) => x.toJson()));

class StrategyReview extends Model {
  int id;
  int habitId;
  int strategyId;
  int achievedMinutes;
  int inhibitTimes;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime softDeletedAt;

  StrategyReview({
    this.id,
    this.habitId,
    this.strategyId,
    this.achievedMinutes,
    this.inhibitTimes,
    this.createdAt,
    this.updatedAt,
    this.softDeletedAt,
  });

  factory StrategyReview.fromJson(Map<String, dynamic> json) =>
      new StrategyReview(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        softDeletedAt: json['soft_deleted_at'] != null
            ? DateTime.parse(json["soft_deleted_at"]).toLocal()
            : null,
        id: json["id"],
        habitId: json["habit_id"],
        strategyId: json["strategy_id"],
        achievedMinutes: json["achieved_minutes"],
        inhibitTimes: json["inhibit_times"],
      );

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "soft_deleted_at": softDeletedAt.toIso8601String(),
        "id": id,
        "habit_id": habitId,
        "strategy_id": strategyId,
        "achieved_minutes": achievedMinutes,
        "inhibit_times": inhibitTimes,
      };
}
