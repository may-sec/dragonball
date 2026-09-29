// lib/features/dragonball/data/dragonball_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/errors/failure.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../models/dragonball_models.dart';
import '../models/paginated_response.dart';

final class DragonBallRepository {
  final http.Client _client;
  const DragonBallRepository(this._client);

  // Route 1: Browse & Filter Characters
  // Fetches a paginated or filtered list of characters from the backend.
  // Parameters:
  // - `page`: Target page number for pagination (defaults to 1).
  // - `limit`: Number of items requested per page (defaults to 10).
  // - `name`: Optional search substring to filter by character name.
  // - `gender`: Optional gender filter ('Male', 'Female', 'Unknown', or 'ALL').
  // - `race`: Optional race filter ('Saiyan', 'Human', etc., or 'ALL').
  // - `affiliation`: Optional faction filter ('Z Fighter', etc., or 'ALL').

  Future<Result<Page<Character>, Failure>> fetchCharacters({
    int page = 1,
    int limit = 10,
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) async {

    final queryParams = <String, String>{};

    if (name != null && name.trim().isNotEmpty) queryParams['name'] = name.trim();
    if (gender != null && gender != 'ALL') queryParams['gender'] = gender;
    if (race != null && race != 'ALL') queryParams['race'] = race;
    if (affiliation != null && affiliation != 'ALL') queryParams['affiliation'] = affiliation;

    final isFiltered = queryParams.isNotEmpty;

    // CRITICAL API BEHAVIOR WORKAROUND:
    // The Dragon Ball API returns a flat JSON Array `[...]` when filters (name/race/etc.) are passed,
    // but returns an envelope object `{"items": [...], "meta": {...}}` only when querying pagination.
    // If filters are active, passing page/limit can cause API rejections, so only paginate unfiltered queries.
    if (!isFiltered) {
      queryParams['page'] = '$page';
      queryParams['limit'] = '$limit';
    }

    final uri = ApiEndpoints.characters(queryParams);

  // Dispatches the network call and parses through the polymorphic response handler.
    return _fetchFlexibleList(
      uri: uri,
      currentPage: page,
      parser: (json) => Character.fromJson(json),
    );
  }

  // Route 3: Browse & Filter Planets
  // Fetches a paginated or filtered list of planets from the backend.
  // Parameters:
  // - `page`: Target page number for pagination (defaults to 1).
  // - `limit`: Number of items requested per page (defaults to 10).
  // - `name`: Optional search substring to filter by planet name.
  // - `isDestroyed`: Optional boolean flag filtering by destruction status (null = all).
  Future<Result<Page<Planet>, Failure>> fetchPlanets({
    int page = 1,
    int limit = 10,
    String? name,
    bool? isDestroyed,
  }) async {
    final queryParams = <String, String>{};

    if (name != null && name.trim().isNotEmpty) queryParams['name'] = name.trim();
    if (isDestroyed != null) queryParams['isDestroyed'] = '$isDestroyed';

    final isFiltered = queryParams.isNotEmpty;

    if (!isFiltered) {
      queryParams['page'] = '$page';
      queryParams['limit'] = '$limit';
    }

    final uri = ApiEndpoints.planets(queryParams);

    return _fetchFlexibleList(
      uri: uri,
      currentPage: page,
      parser: (json) => Planet.fromJson(json),
    );
  }

  Future<Result<CharacterProfile, Failure>> fetchCharacterProfile(int id) async {
    return _fetchSingle(
      ApiEndpoints.CharacterProfile(id),
      (json) => CharacterProfile.fromJson(json),
    );
  }

  Future<Result<Planet, Failure>> fetchPlanetDetail(int id) async {
    return _fetchSingle(
      ApiEndpoints.planetDetail(id),
      (json) => Planet.fromJson(json),
    );
  }

  // Private Helper 1: Polymorphic Flexible List Deserializer

  // Polymorphic helper method parsing two distinct API response formats:
  // 1. Flat List: Returned when searching by filter parameters (e.g., `[{...}, {...}]`).
  // 2. Map with Envelope: Returned on paginated browse calls (e.g., `{"items": [...], "meta": {...}}`).
  // Generic parameter `<T>` represents the target entity type (Character or Planet).
  Future<Result<Page<T>, Failure>> _fetchFlexibleList<T>({
    required Uri uri,
    required int currentPage,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return Err(ServerFailure('Server returned rejection', response.statusCode));
      }

      // Deserializes the raw response body string into dynamic Dart data structures.
      final decoded = jsonDecode(response.body);

      // Branch 1: The response is a flat JSON Array (typical when filters are applied).

      if (decoded is List) {
        return Ok(
          Page<T>(
            // Maps each item in the raw array through the provided parser closure.
            items: decoded.map((item) => parser(item as Map<String, dynamic>)).toList(),
            // When filtering, the API returns all matching results in a single flat list.
            currentPage: 1,
            totalPages: 1,
            hasNext: false,
          ),
        );
      }

      // Branch 2: The response is an enveloped JSON Object (standard paginated response).
      if (decoded is Map<String, dynamic>) {
        final rawItems = decoded['items'] as List<dynamic>? ?? [];
        final meta = decoded['meta'] as Map<String, dynamic>? ?? {};
        final links = decoded['links'] as Map<String, dynamic>? ?? {};

        return Ok(
          Page<T>(
            // Maps each dynamic entry in rawItems into the typed domain entity.
            items: rawItems.map((e) => parser(e as Map<String, dynamic>)).toList(),
            currentPage: meta['currentPage'] as int? ?? currentPage,
            totalPages: meta['totalPages'] as int? ?? 1,
            hasNext: (links['next'] as String? ?? '').isNotEmpty,
          ),
        );
      }

      // Fallback if the returned JSON is neither a List nor a Map.
      return const Err(ParseFailure('Unexpected response shape received from API'));
    } on SocketException {
      // Intercepts transport-level connectivity errors (offline, DNS failures, connection drops).
      return const Err(NetworkFailure('No active internet connection.'));
    } catch (e) {
      // Intercepts JSON parsing or type-casting exceptions.
      return Err(ParseFailure('Error processing response: $e'));
    }
  }

  // Private Helper 2: Single Entity Deserializer
  // Generic private helper for retrieving and parsing a single entity by URI.
  // Parameter `<T>` represents the target entity type (e.g., CharacterProfile or Planet).
  Future<Result<T, Failure>> _fetchSingle<T>(
    Uri uri,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return Err(ServerFailure('Server rejection', response.statusCode));
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(parser(decoded));
    } on SocketException {
      return const Err(NetworkFailure('No active internet connection.'));
    } catch (e) {
      return Err(ParseFailure('Failed to fetch details: $e'));
    }
  }
}