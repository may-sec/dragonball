import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/failure.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../models/dragonball_models.dart';
import '../models/paginated_response.dart';

class DragonBallRepository {
  DragonBallRepository(this._client);

  final http.Client _client;

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

    // The API may return a flat array when filters are active.
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

  Future<Result<Page<T>, Failure>> _fetchFlexibleList<T>({
    required Uri uri,
    required int currentPage,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Err(
          ServerFailure(
            'The server returned HTTP ${response.statusCode}.',
            response.statusCode,
          ),
        );
      }

      final decoded = jsonDecode(response.body);

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
    } on SocketException {
      return const Err(
        NetworkFailure('No internet connection is available.'),
      );
    } on TimeoutException {
      return const Err(
        NetworkFailure('The request timed out. Try again.'),
      );
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
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Err(
          ServerFailure(
            'The server returned HTTP ${response.statusCode}.',
            response.statusCode,
          ),
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return const Err(
          ParseFailure('The API returned an unexpected JSON shape.'),
        );
      }

      return Ok(parser(_toMap(decoded)));
    } on SocketException {
      return const Err(
        NetworkFailure('No internet connection is available.'),
      );
    } on TimeoutException {
      return const Err(
        NetworkFailure('The request timed out. Try again.'),
      );
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