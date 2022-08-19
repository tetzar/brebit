
import 'model.dart';

List<Ticket> ticketFromJson(List<dynamic> decodedList) =>
    new List<Ticket>.from(decodedList.cast<Map<String, dynamic>>().map((x) => Ticket.fromJson(x)));

List<Map> ticketToJson(List<Ticket> remaining) =>
    new List<Map>.from(remaining.map((x) => x.toJson()));

class Ticket extends Model {
  int id;
  int setNumber;
  int remaining;
  int habitId;
  DateTime createdAt;
  DateTime updatedAt;

  Ticket({
    required this.id,
    required this.setNumber,
    required this.remaining,
    required this.habitId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => new Ticket(
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        updatedAt: DateTime.parse(json["updated_at"]).toLocal(),
        id: json["id"],
        setNumber: json["set_number"],
        remaining: json["remaining"],
        habitId: json["habit_id"],
      );

  Map<String, dynamic> toJson() => {
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "id": id,
        "set_number": setNumber,
        "remaining": remaining,
        "habit_id": habitId,
      };
}
