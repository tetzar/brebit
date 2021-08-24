
import 'model.dart';

// ignore: non_constant_identifier_names
List<Ticket> TicketFromJson(List<dynamic> decodedList) =>
    new List<Ticket>.from(decodedList.cast<Map>().map((x) => Ticket.fromJson(x)));

// ignore: non_constant_identifier_names
List<Map> TicketToJson(List<Ticket> remaining) =>
    new List<dynamic>.from(remaining.map((x) => x.toJson()));

class Ticket extends Model {
  int id;
  int setNumber;
  int remaining;
  int habitId;
  DateTime createdAt;
  DateTime updatedAt;

  Ticket({
    this.id,
    this.setNumber,
    this.remaining,
    this.habitId,
    this.createdAt,
    this.updatedAt,
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
