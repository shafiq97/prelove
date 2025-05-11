import 'outfit_model.dart';

class Event {
  final int id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? location;
  final int? outfitId;
  final String? outfitName;
  final Outfit? outfit;
  final String createdAt;
  final String? updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.location,
    this.outfitId,
    this.outfitName,
    this.outfit,
    required this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      eventDate: DateTime.parse(json['event_date']),
      location: json['location'],
      outfitId: json['outfit_id'],
      outfitName: json['outfit_name'],
      outfit: json['outfit'] != null ? Outfit.fromJson(json['outfit']) : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date':
          eventDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'location': location,
      'outfit_id': outfitId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
