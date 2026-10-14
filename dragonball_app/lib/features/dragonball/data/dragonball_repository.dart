
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



  /// Fetches a response from the API.
  ///
  /// Cache writes happen only after the response passes the expected
  /// JSON/model parsing in _fetchFlexibleList or _fetchSingle.
  ///
  /// Network failures are returned to the caller instead of being
  /// hidden by a cached response. The notifier can preserve existing
  /// cached UI data while also reporting the failure.
  Future<String> _requestBody(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final status = response.statusCode;

        final message = switch (status) {
          400 => 'The request was invalid. Please check your filters.',
          401 => 'Authentication is required to access this resource.',
          403 => 'You do not have permission to access this resource.',
          404 => 'The requested resource was not found.',
          408 => 'The server timed out while processing the request.',
          429 => 'Too many requests. Please wait and try again.',
          >= 500 => 'The server encountered an error. Please try again.',
          _ => 'The server returned HTTP $status.',
        };

        throw _RepositoryRequestException(
          ServerFailure(message, status),
        );
      }

      return response.body;
    } on _RepositoryRequestException {
      rethrow;
    } on SocketException {
      throw const _RepositoryRequestException(
        NetworkFailure(
          'No internet connection. Check your connection and try again.',
        ),
      );
    } on TimeoutException {
      throw const _RepositoryRequestException(
        NetworkFailure(
          'The request timed out. Check your connection and try again.',
        ),
      );
    } on http.ClientException {
      throw const _RepositoryRequestException(
        NetworkFailure(
          'Could not connect to the server. Check your internet connection.',
        ),
      );
    } catch (error) {
      throw _RepositoryRequestException(
        UnknownFailure(
          'An unexpected network error occurred: $error',
        ),
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

        final page = Page<T>(
          items: List.unmodifiable(items),
          currentPage: 1,
          totalPages: 1,
          hasNext: false,
        );

        await _cache.write(uri.toString(), responseBody);

        return Ok(page);
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

        if (rawItems is! List) {
          return const Err(
            ParseFailure(
              'The API response does not contain a valid items list.',
            ),
          );
        }

        final items = rawItems
            .map((entry) => parser(_toMap(entry)))
            .toList();

        final current = _toInt(meta['currentPage'], currentPage);
        final total = _toInt(meta['totalPages'], 1);
        final nextLink = links['next']?.toString() ?? '';

        final page = Page<T>(
          items: List.unmodifiable(items),
          currentPage: current,
          totalPages: total,
          hasNext: nextLink.isNotEmpty || current < total,
        );

        await _cache.write(uri.toString(), responseBody);

        return Ok(page);
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

      // 1. Parse and validate the response first.
      final value = parser(_toMap(decoded));

      // 2. Cache only after parsing succeeds.
      await _cache.write(uri.toString(), responseBody);

      // 3. Return the validated model.
      return Ok(value);
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
