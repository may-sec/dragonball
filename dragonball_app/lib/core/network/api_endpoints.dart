// lib/core/network/api_endpoints.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 'abstract final class' (Dart 3 feature):
// Combining 'abstract' and 'final' completely prevents this utility class from
// being instantiated (no `ApiEndpoints()`) or extended/subclassed by any class.
// It acts strictly as a static namespace for URL builders.

// class abstract final creates an uninstantiable static namespace.
abstract final class ApiEndpoints {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://dragonball-api.com/api';

  // Accepts an optional map of query parameters (e.g. {'page': '1', 'gender': 'Male'}).
  // Uses Uri.replace() to immutably inject queryParameters into the parsed base URI.
  static Uri characters([Map<String, String>? queryParams]) =>
      Uri.parse('$baseUrl/characters').replace(queryParameters: queryParams);

  static Uri CharacterProfile(int id) =>
      Uri.parse('$baseUrl/characters/$id');

  static Uri planets([Map<String, String>? queryParams]) =>
      Uri.parse('$baseUrl/planets').replace(queryParameters: queryParams);

  static Uri planetDetail(int id) =>
      Uri.parse('$baseUrl/planets/$id');
}