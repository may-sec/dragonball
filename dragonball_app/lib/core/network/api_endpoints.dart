// lib/core/network/api_endpoints.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiEndpoints {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://dragonball-api.com/api';

  static Uri characters([Map<String, String>? queryParams]) =>
      Uri.parse('$baseUrl/characters').replace(queryParameters: queryParams);

  static Uri characterDetail(int id) =>
      Uri.parse('$baseUrl/characters/$id');

  static Uri planets([Map<String, String>? queryParams]) =>
      Uri.parse('$baseUrl/planets').replace(queryParameters: queryParams);

  static Uri planetDetail(int id) =>
      Uri.parse('$baseUrl/planets/$id');
}