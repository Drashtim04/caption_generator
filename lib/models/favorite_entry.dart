import 'dart:convert';

class FavoriteEntry {
  final String id;
  final String caption;
  final String? imageBase64;
  final DateTime savedAt;

  FavoriteEntry({
    required this.id,
    required this.caption,
    this.imageBase64,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caption': caption,
      'imageBase64': imageBase64,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  static FavoriteEntry fromMap(Map<String, dynamic> map) {
    return FavoriteEntry(
      id: map['id']?.toString() ?? '',
      caption: map['caption']?.toString() ?? '',
      imageBase64: map['imageBase64']?.toString(),
      savedAt: DateTime.tryParse(map['savedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
