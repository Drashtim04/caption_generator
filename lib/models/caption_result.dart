import 'dart:convert';

class CaptionHistoryEntry {
  final String id;
  final DateTime createdAt;
  final String description;
  final List<String> captions;
  final List<String> tags;
  final String? mood;
  final String? imageBase64;

  CaptionHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.captions,
    required this.tags,
    required this.mood,
    this.imageBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "createdAt": createdAt.toIso8601String(),
      "description": description,
      "captions": captions,
      "tags": tags,
      "mood": mood,
      "imageBase64": imageBase64,
    };
  }

  String toJson() => jsonEncode(toMap());

  static CaptionHistoryEntry fromMap(Map<String, dynamic> map) {
    return CaptionHistoryEntry(
      id: map["id"]?.toString() ?? "",
      createdAt: DateTime.tryParse(map["createdAt"]?.toString() ?? "") ??
          DateTime.now(),
      description: map["description"]?.toString() ?? "",
      captions: (map["captions"] is List)
          ? (map["captions"] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : <String>[],
      tags: (map["tags"] is List)
          ? (map["tags"] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : <String>[],
      mood: map["mood"]?.toString(),
      imageBase64: map["imageBase64"]?.toString(),
    );
  }
}
