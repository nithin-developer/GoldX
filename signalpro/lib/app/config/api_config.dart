class ApiConfig {
  // Override with: flutter run --dart-define=API_BASE_URL=http://<host>:8000/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.goldxvip.com/api/v1',
    // defaultValue: 'http://10.17.234.251:8000/api/v1',
  );
}
