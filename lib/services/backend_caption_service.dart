import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import '../utils/app_constants.dart';

class BackendCaptionService {
  Future<BackendCaptionResult> generate(
    Uint8List imageBytes,
  ) async {
    final baseUrl = AppConstants.backendBaseUrl;

    if (baseUrl.isEmpty) {
      throw Exception(
        "Missing BACKEND_BASE_URL. "
        "Set it using --dart-define.",
      );
    }

    final uri = Uri.parse(
      "$baseUrl${AppConstants.captionEndpoint}",
    );

    print("\n========== CAPTION API REQUEST ==========");
    print("URL: $uri");
    print("Image Size: ${imageBytes.length} bytes");

    final request = http.MultipartRequest(
      "POST",
      uri,
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        "image",
        imageBytes,
        filename: "image.jpg",
        contentType: http_parser.MediaType(
          "image",
          "jpeg",
        ),
      ),
    );

    http.StreamedResponse streamedResponse;

    try {
      streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
    } catch (e) {
      print("REQUEST SEND ERROR: $e");

      throw Exception(
        "Failed to connect to backend server.\n\n$e",
      );
    }

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    print("\n========== API RESPONSE ==========");
    print("STATUS CODE: ${response.statusCode}");
    print("BODY:");
    print(response.body);

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (e) {
      print("\nJSON PARSE ERROR: $e");

      throw Exception(
        "Server returned invalid JSON.\n\n"
        "Status Code: ${response.statusCode}\n\n"
        "Response Body:\n${response.body}",
      );
    }

    if (data is! Map<String, dynamic>) {
      throw Exception(
        "Unexpected API response format.\n\n"
        "${response.body}",
      );
    }

    final successValue = data["success"];

    final isSuccess =
        successValue == true ||
        successValue
                ?.toString()
                .toLowerCase() ==
            "true";

    if (response.statusCode != 200 || !isSuccess) {
      final errorMessage =
          data["message"]?.toString() ??
          data["error"]?.toString() ??
          data["details"]?.toString() ??
          response.body;

      throw Exception(
        "Caption API failed.\n\n$errorMessage",
      );
    }

    final description =
        data["description"]?.toString() ??
        data["image_description"]?.toString() ??
        data["imageDescription"]?.toString();

    if (description == null ||
        description.trim().isEmpty) {
      throw Exception(
        "Missing description in API response.\n\n"
        "${response.body}",
      );
    }

    final captionsRaw = data["captions"];

    final tagsRaw =
        data["tags"] ??
        data["hashtags"] ??
        data["hash_tags"] ??
        data["hashTags"];

    final mood = data["mood"]?.toString();

    final captions = _parseList(
      captionsRaw,
      splitOn: "\n",
    );

    final tags = _normalizeTags(
      _parseList(
        tagsRaw,
        splitOn: ",",
      ),
    );

    print("\n========== PARSED RESPONSE ==========");
    print("Description: $description");
    print("Captions Count: ${captions.length}");
    print("Tags Count: ${tags.length}");
    print("Mood: $mood");

    return BackendCaptionResult(
      description: description,
      captions: captions,
      tags: tags,
      mood: mood,
    );
  }

  List<String> _parseList(
    Object? raw, {
    String splitOn = "\n",
  }) {
    if (raw == null) {
      return <String>[];
    }

    if (raw is List) {
      return raw
          .map(
            (e) => e.toString().trim(),
          )
          .where(
            (e) => e.isNotEmpty,
          )
          .toList();
    }

    if (raw is String) {
      return raw
          .split(splitOn)
          .map(
            (e) => e.trim(),
          )
          .where(
            (e) => e.isNotEmpty,
          )
          .toList();
    }

    return <String>[];
  }

  List<String> _normalizeTags(
    List<String> tags,
  ) {
    return tags
        .map((tag) {
          final trimmed = tag.trim();

          if (trimmed.isEmpty) {
            return "";
          }

          return trimmed.startsWith("#")
              ? trimmed
              : "#$trimmed";
        })
        .where(
          (e) => e.isNotEmpty,
        )
        .toList();
  }
}

class BackendCaptionResult {
  final String description;
  final List<String> captions;
  final List<String> tags;
  final String? mood;

  BackendCaptionResult({
    required this.description,
    required this.captions,
    required this.tags,
    required this.mood,
  });
}