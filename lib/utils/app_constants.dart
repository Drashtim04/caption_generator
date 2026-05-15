class AppConstants {
  // Backend API
  static const captionEndpoint = "/api/generate-captions";

  // Daily limit
  static const dailyMaxGenerations = 25;

  // Local history storage
  static const historyMaxEntries = 30;

  // Backend base URL (required). Do NOT hardcode in UI.
  // flutter run --dart-define=BACKEND_BASE_URL=https://your-api.com
  static const backendBaseUrl = String.fromEnvironment(
    "BACKEND_BASE_URL",
    defaultValue: "https://caption-generator-backend-vrh1.onrender.com",
  );
}
