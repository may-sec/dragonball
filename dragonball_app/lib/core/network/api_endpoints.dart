abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dragonball-api.com/api',
  );

  static Uri characters([Map<String, String>? queryParams]) {
    return Uri.parse('$baseUrl/characters').replace(
      queryParameters:
          (queryParams?.isEmpty ?? true) ? null : queryParams,
    );
  }

  static Uri characterProfile(int id) {
    return Uri.parse('$baseUrl/characters/$id');
  }

  static Uri planets([Map<String, String>? queryParams]) {
    return Uri.parse('$baseUrl/planets').replace(
      queryParameters:
          (queryParams?.isEmpty ?? true) ? null : queryParams,
    );
  }

  static Uri planetDetail(int id) {
    return Uri.parse('$baseUrl/planets/$id');
  }
}