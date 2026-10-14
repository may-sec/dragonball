
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/failure.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../models/dragonball_models.dart';
import '../models/paginated_response.dart';
import 'json_response_cache.dart';

class DragonBallRepository {
  DragonBallRepository(this._client);

  final http.Client _client;
  final JsonResponseCache _cache = JsonResponseCache.instance;

  Future<Result<Page<Character>, Failure>> fetchCharacters({
    int page = 1,
    int limit = 10,
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) async {
    final query = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      query['name'] = name.trim();
    }

    if (gender != null && gender != 'ALL') {
      query['gender'] = gender;
    }

    if (race != null && race != 'ALL') {
      query['race'] = race;
    }

    if (affiliation != null && affiliation != 'ALL') {
      query['affiliation'] = affiliation;
    }

    // Only unfiltered browsing requests use page and limit.
    if (query.isEmpty) {
      query['page'] = '$page';
      query['limit'] = '$limit';
    }

    return _fetchFlexibleList<Character>(
      uri: ApiEndpoints.characters(query),
      currentPage: page,
      parser: Character.fromJson,
    );
  }

  Future<Result<Page<Planet>, Failure>> fetchPlanets({
    int page = 1,
    int limit = 10,
    String? name,
    bool? isDestroyed,
  }) async {
    final query = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      query['name'] = name.trim();
    }

    if (isDestroyed != null) {
      query['isDestroyed'] = '$isDestroyed';
    }

    if (query.isEmpty) {
      query['page'] = '$page';
      query['limit'] = '$limit';
    }

    return _fetchFlexibleList<Planet>(
      uri: ApiEndpoints.planets(query),
      currentPage: page,
      parser: Planet.fromJson,
    );
  }

  Future<Result<CharacterProfile, Failure>> fetchCharacterProfile(
    int id,
  ) {
    return _fetchSingle(
      ApiEndpoints.characterProfile(id),
      CharacterProfile.fromJson,
    );
  }

  Future<Result<Planet, Failure>> fetchPlanetDetail(int id) {
    return _fetchSingle(
      ApiEndpoints.planetDetail(id),
      Planet.fromJson,
    );
  }


  // Reads cached character results without making a network request.
  Future<Page<Character>?> readCachedCharacters({
    int page = 1,
    int limit = 10,
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) async {
    final query = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      query['name'] = name.trim();
    }

    if (gender != null && gender != 'ALL') {
      query['gender'] = gender;
    }

    if (race != null && race != 'ALL') {
      query['race'] = race;
    }

    if (affiliation != null && affiliation != 'ALL') {
      query['affiliation'] = affiliation;
    }

    if (query.isEmpty) {
      query['page'] = '$page';
      query['limit'] = '$limit';
    }

    return _readCachedFlexibleList<Character>(
      uri: ApiEndpoints.characters(query),
      currentPage: page,
      parser: Character.fromJson,
    );
  }

  // Reads cached planet results without making a network request.
  Future<Page<Planet>?> readCachedPlanets({
    int page = 1,
    int limit = 10,
    String? name,
    bool? isDestroyed,
  }) async {
    final query = <String, String>{};

    if (name != null && name.trim().isNotEmpty) {
      query['name'] = name.trim();
    }

    if (isDestroyed != null) {
      query['isDestroyed'] = '$isDestroyed';
    }

    if (query.isEmpty) {
      query['page'] = '$page';
      query['limit'] = '$limit';
    }

    return _readCachedFlexibleList<Planet>(
      uri: ApiEndpoints.planets(query),
      currentPage: page,
      parser: Planet.fromJson,
    );
  }

  // Reads a cached character profile without making a network request.
  Future<CharacterProfile?> readCachedCharacterProfile(int id) {
    return _readCachedSingle<CharacterProfile>(
      ApiEndpoints.characterProfile(id),
      CharacterProfile.fromJson,
    );
  }

  // Reads cached planet details without making a network request.
  Future<Planet?> readCachedPlanetDetail(int id) {
    return _readCachedSingle<Planet>(
      ApiEndpoints.planetDetail(id),
      Planet.fromJson,
    );
  }

  Future<Page<T>?> _readCachedFlexibleList<T>({
    required Uri uri,
    required int currentPage,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final cached = await _cache.read(uri.toString());

      if (cached == null) return null;

      final decoded = jsonDecode(cached.body);

      if (decoded is List) {
        final items = decoded
            .map((entry) => parser(_toMap(entry)))
            .toList();

        return Page<T>(
          items: List.unmodifiable(items),
          currentPage: 1,
          totalPages: 1,
          hasNext: false,
        );
      }

      if (decoded is Map) {
        final body = _toMap(decoded);

        final rawItems = body['items'];
        final meta = body['meta'] is Map
            ? _toMap(body['meta'])
            : <String, dynamic>{};
        final links = body['links'] is Map
            ? _toMap(body['links'])
            : <String, dynamic>{};

        final items = rawItems is List
            ? rawItems.map((entry) => parser(_toMap(entry))).toList()
            : <T>[];

        final current = _toInt(meta['currentPage'], currentPage);
        final total = _toInt(meta['totalPages'], 1);
        final nextLink = links['next']?.toString() ?? '';

        return Page<T>(
          items: List.unmodifiable(items),
          currentPage: current,
          totalPages: total,
          hasNext: nextLink.isNotEmpty || current < total,
        );
      }

      return null;
    } catch (_) {
      // Missing, corrupted, or incompatible cache is not fatal.
      return null;
    }
  }

  Future<T?> _readCachedSingle<T>(
    Uri uri,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final cached = await _cache.read(uri.toString());

      if (cached == null) return null;

      final decoded = jsonDecode(cached.body);

      if (decoded is! Map) return null;

      return parser(_toMap(decoded));
    } catch (_) {
      // The network request can still provide the data.
      return null;
    }
  }


  /// Fetches JSON from the network and caches successful responses.
  ///
  /// If the request fails, a previously cached response is used when
  /// available. The cache key includes the complete request URI.
  Future<String> _requestBody(Uri uri) async {
    final cacheKey = uri.toString();

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final cached = await _cache.read(cacheKey);

        if (cached != null) {
          return cached.body;
        }

        throw _RepositoryRequestException(
          ServerFailure(
            'The server returned HTTP ${response.statusCode}.',
            response.statusCode,
          ),
        );
      }

      // Cache only successful responses containing valid JSON.
      await _cache.write(cacheKey, response.body);

      return response.body;
    } on _RepositoryRequestException {
      rethrow;
    } on SocketException {
      final cached = await _cache.read(cacheKey);

      if (cached != null) {
        return cached.body;
      }

      throw const _RepositoryRequestException(
        NetworkFailure('No internet connection is available.'),
      );
    } on TimeoutException {
      final cached = await _cache.read(cacheKey);

      if (cached != null) {
        return cached.body;
      }

      throw const _RepositoryRequestException(
        NetworkFailure('The request timed out. Try again.'),
      );
    } catch (error) {
      // Also attempt cache fallback for unexpected request failures.
      final cached = await _cache.read(cacheKey);

      if (cached != null) {
        return cached.body;
      }

      throw _RepositoryRequestException(
        UnknownFailure('Could not fetch the response: $error'),
      );
    }
  }

  Future<Result<Page<T>, Failure>> _fetchFlexibleList<T>({
    required Uri uri,
    required int currentPage,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final responseBody = await _requestBody(uri);
      final decoded = jsonDecode(responseBody);

      if (decoded is List) {
        final items = decoded
            .map((entry) => parser(_toMap(entry)))
            .toList();

        return Ok(
          Page<T>(
            items: List.unmodifiable(items),
            currentPage: 1,
            totalPages: 1,
            hasNext: false,
          ),
        );
      }

      if (decoded is Map) {
        final body = _toMap(decoded);

        final rawItems = body['items'];
        final meta = body['meta'] is Map
            ? _toMap(body['meta'])
            : <String, dynamic>{};
        final links = body['links'] is Map
            ? _toMap(body['links'])
            : <String, dynamic>{};

        final items = rawItems is List
            ? rawItems.map((entry) => parser(_toMap(entry))).toList()
            : <T>[];

        final current = _toInt(meta['currentPage'], currentPage);
        final total = _toInt(meta['totalPages'], 1);
        final nextLink = links['next']?.toString() ?? '';

        return Ok(
          Page<T>(
            items: List.unmodifiable(items),
            currentPage: current,
            totalPages: total,
            hasNext: nextLink.isNotEmpty || current < total,
          ),
        );
      }

      return const Err(
        ParseFailure('The API returned an unexpected JSON shape.'),
      );
    } on _RepositoryRequestException catch (error) {
      return Err(error.failure);
    } on FormatException {
      return const Err(
        ParseFailure('The API response was not valid JSON.'),
      );
    } catch (error) {
      return Err(
        UnknownFailure('Could not process the response: $error'),
      );
    }
  }

  Future<Result<T, Failure>> _fetchSingle<T>(
    Uri uri,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final responseBody = await _requestBody(uri);
      final decoded = jsonDecode(responseBody);

      if (decoded is! Map) {
        return const Err(
          ParseFailure('The API returned an unexpected JSON shape.'),
        );
      }

      return Ok(parser(_toMap(decoded)));
    } on _RepositoryRequestException catch (error) {
      return Err(error.failure);
    } on FormatException {
      return const Err(
        ParseFailure('The API response was not valid JSON.'),
      );
    } catch (error) {
      return Err(
        UnknownFailure('Could not process the response: $error'),
      );
    }
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    throw const FormatException('Expected a JSON object.');
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class _RepositoryRequestException implements Exception {
  const _RepositoryRequestException(this.failure);

  final Failure failure;
}
