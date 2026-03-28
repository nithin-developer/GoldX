class ApiConfig {
  // Override with: flutter run --dart-define=API_BASE_URL=http://<host>:8000/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.150.95.251:8000/api/v1',
  );
}
