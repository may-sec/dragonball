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

  Future<Result<PaginatedList<CharacterSummary>, Failure>> fetchCharacters({
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

    return _fetchFlexibleList(
      uri: uri,
      currentPage: page,
      parser: (json) => CharacterSummary.fromJson(json),
    );
  }

  Future<Result<PaginatedList<Planet>, Failure>> fetchPlanets({
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

  Future<Result<CharacterDetail, Failure>> fetchCharacterDetail(int id) async {
    return _fetchSingle(
      ApiEndpoints.characterDetail(id),
      (json) => CharacterDetail.fromJson(json),
    );
  }

  Future<Result<Planet, Failure>> fetchPlanetDetail(int id) async {
    return _fetchSingle(
      ApiEndpoints.planetDetail(id),
      (json) => Planet.fromJson(json),
    );
  }

  // Polymorphic helper method parsing two distinct API response formats:
  // 1. Flat List: Returned when searching by filter parameters (e.g., `[{...}, {...}]`).
  // 2. Map with Envelope: Returned on paginated browse calls (e.g., `{"items": [...], "meta": {...}}`).
  Future<Result<PaginatedList<T>, Failure>> _fetchFlexibleList<T>({
    required Uri uri,
    required int currentPage,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return Err(ServerFailure('Server returned rejection', response.statusCode));
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return Ok(
          PaginatedList<T>(
            items: decoded.map((item) => parser(item as Map<String, dynamic>)).toList(),
            currentPage: 1,
            totalPages: 1,
            hasNext: false,
          ),
        );
      }

      if (decoded is Map<String, dynamic>) {
        final rawItems = decoded['items'] as List<dynamic>? ?? [];
        final meta = decoded['meta'] as Map<String, dynamic>? ?? {};
        final links = decoded['links'] as Map<String, dynamic>? ?? {};

        return Ok(
          PaginatedList<T>(
            items: rawItems.map((e) => parser(e as Map<String, dynamic>)).toList(),
            currentPage: meta['currentPage'] as int? ?? currentPage,
            totalPages: meta['totalPages'] as int? ?? 1,
            hasNext: (links['next'] as String? ?? '').isNotEmpty,
          ),
        );
      }

      return const Err(ParseFailure('Unexpected response shape received from API'));
    } on SocketException {
      return const Err(NetworkFailure('No active internet connection.'));
    } catch (e) {
      return Err(ParseFailure('Error processing response: $e'));
    }
  }

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