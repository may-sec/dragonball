import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../../core/errors/failure.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/result/result.dart';
import '../models/dragonball_models.dart';
import '../models/paginated_response.dart';
import 'json_response_cache.dart';

// =============================================================================
// LEARN (HTTP caching, two different worlds):
//
//  ANDROID (dart:io HttpClient): there is NO HTTP cache. Every GET reaches the
//  server. So we do conditional requests ourselves: we saved the ETag of the
//  last response; we send it back as `If-None-Match`; if nothing changed the
//  server answers `304 Not Modified` with no body and we reuse the cached one.
//
//  WEB (browser): the BROWSER owns an HTTP cache. This API answers with
//  `Cache-Control: max-age=864000` (10 days), so a plain GET may never leave
//  the browser for 10 days. And we cannot do the conditional request by hand:
//    * `If-None-Match` is not a "simple" header, so sending it triggers a CORS
//      preflight that the server may reject, and
//    * JavaScript cannot even READ the ETag unless the server lists it in
//      Access-Control-Expose-Headers.
//  So on web, every fetch*() (= "ask the server") adds a throw-away query
//  parameter that makes the URL unique and steps around the browser cache.
//  The cache KEY stays the clean URL, so cached data is still found offline.
//
// A "fetch" here always means "ask the server". Reading without asking is what
// the readCached*() methods are for.
// =============================================================================

/// Query parameter used only on web to bypass the browser HTTP cache.
/// If the API ever rejects unknown parameters, set [DragonBallRepository]'s
/// `bypassBrowserCache` to false and rely on the 10-day browser cache instead.
const String kWebCacheBusterParam = '_cb';

class DragonBallRepository {
  DragonBallRepository(
    this._client, {
    JsonResponseCache? cache,
    bool? isWeb,
    bool bypassBrowserCache = true,
    Duration requestTimeout = const Duration(seconds: 15),
  })  : _cache = cache ?? JsonResponseCache.instance,
        _isWeb = isWeb ?? kIsWeb,
        _bypassBrowserCache = bypassBrowserCache,
        _requestTimeout = requestTimeout;

  final http.Client _client;
  final JsonResponseCache _cache;
  final bool _isWeb;
  final bool _bypassBrowserCache;
  final Duration _requestTimeout;

  // ---------------------------------------------------------------------------
  // URLs. ONE builder per resource, used by BOTH fetch and readCached, so the
  // cache key can never drift away from the request URL.
  // ---------------------------------------------------------------------------

  Uri _charactersUri({
    required int page,
    required int limit,
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) {
    final query = <String, String>{};

    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      query['name'] = trimmedName;
    }
    if (gender != null && gender != 'ALL') query['gender'] = gender;
    if (race != null && race != 'ALL') query['race'] = race;
    if (affiliation != null && affiliation != 'ALL') {
      query['affiliation'] = affiliation;
    }

    // Only unfiltered browsing requests use page and limit.
    if (query.isEmpty) {
      query['page'] = '$page';
      query['limit'] = '$limit';
    }

    return ApiEndpoints.characters(query);
  }

  Uri _planetsUri({
    required int page,
    required int limit,
    String? name,
    bool? isDestroyed,
  }) {
    final query = <String, String>{};

    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      query['name'] = trimmedName;
    }
    if (isDestroyed != null) query['isDestroyed'] = '$isDestroyed';

    if (query.isEmpty) {
      query['page'] = '$page';
      query['limit'] = '$limit';
    }

    return ApiEndpoints.planets(query);
  }

  // ---------------------------------------------------------------------------
  // Network reads ("ask the server")
  // ---------------------------------------------------------------------------

  Future<Result<Page<Character>, Failure>> fetchCharacters({
    int page = 1,
    int limit = 10,
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) {
    return _fetchParsed<Page<Character>>(
      _charactersUri(
        page: page,
        limit: limit,
        name: name,
        gender: gender,
        race: race,
        affiliation: affiliation,
      ),
      (body) => _parsePage(body, page, Character.fromJson),
    );
  }

  Future<Result<Page<Planet>, Failure>> fetchPlanets({
    int page = 1,
    int limit = 10,
    String? name,
    bool? isDestroyed,
  }) {
    return _fetchParsed<Page<Planet>>(
      _planetsUri(
        page: page,
        limit: limit,
        name: name,
        isDestroyed: isDestroyed,
      ),
      (body) => _parsePage(body, page, Planet.fromJson),
    );
  }

  Future<Result<CharacterProfile, Failure>> fetchCharacterProfile(int id) {
    return _fetchParsed<CharacterProfile>(
      ApiEndpoints.characterProfile(id),
      (body) => _parseSingle(body, CharacterProfile.fromJson),
    );
  }

  Future<Result<Planet, Failure>> fetchPlanetDetail(int id) {
    return _fetchParsed<Planet>(
      ApiEndpoints.planetDetail(id),
      (body) => _parseSingle(body, Planet.fromJson),
    );
  }

  // ---------------------------------------------------------------------------
  // Cache-only reads (never touch the network)
  // ---------------------------------------------------------------------------

  Future<Page<Character>?> readCachedCharacters({
    int page = 1,
    int limit = 10,
    String? name,
    String? gender,
    String? race,
    String? affiliation,
  }) {
    return _readCached<Page<Character>>(
      _charactersUri(
        page: page,
        limit: limit,
        name: name,
        gender: gender,
        race: race,
        affiliation: affiliation,
      ),
      (body) => _parsePage(body, page, Character.fromJson),
    );
  }

  Future<Page<Planet>?> readCachedPlanets({
    int page = 1,
    int limit = 10,
    String? name,
    bool? isDestroyed,
  }) {
    return _readCached<Page<Planet>>(
      _planetsUri(
        page: page,
        limit: limit,
        name: name,
        isDestroyed: isDestroyed,
      ),
      (body) => _parsePage(body, page, Planet.fromJson),
    );
  }

  Future<CharacterProfile?> readCachedCharacterProfile(int id) {
    return _readCached<CharacterProfile>(
      ApiEndpoints.characterProfile(id),
      (body) => _parseSingle(body, CharacterProfile.fromJson),
    );
  }

  Future<Planet?> readCachedPlanetDetail(int id) {
    return _readCached<Planet>(
      ApiEndpoints.planetDetail(id),
      (body) => _parseSingle(body, Planet.fromJson),
    );
  }

  Future<T?> _readCached<T>(Uri uri, T Function(String body) parse) async {
    try {
      final cached = await _cache.read(uri.toString());
      if (cached == null) return null;

      return parse(cached.body);
    } catch (_) {
      // Missing, corrupted or incompatible cache is not fatal: the network
      // request can still provide the data.
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Request pipeline
  // ---------------------------------------------------------------------------

  /// request -> parse -> THEN cache. A response that fails to parse is never
  /// written to the cache, so a bad response cannot poison offline data.
  Future<Result<T, Failure>> _fetchParsed<T>(
    Uri uri,
    T Function(String body) parse,
  ) async {
    try {
      final response = await _request(uri);
      final value = parse(response.body);

      // On a 304 this rewrites the same body, which refreshes `cachedAt`.
      await _cache.write(uri.toString(), response.body, etag: response.etag);

      return Ok<T, Failure>(value);
    } on _RepositoryRequestException catch (error) {
      return Err<T, Failure>(error.failure);
    } on _ShapeException catch (error) {
      return Err<T, Failure>(ParseFailure(error.message));
    } on FormatException {
      return Err<T, Failure>(
        const ParseFailure('The API response was not valid JSON.'),
      );
    } catch (error) {
      return Err<T, Failure>(
        UnknownFailure('Could not process the response: $error'),
      );
    }
  }

  Future<_Response> _request(Uri uri) async {
    final cached = await _cache.read(uri.toString());

    // Web cannot send or read validators safely (see the note at the top).
    final validator = _isWeb ? null : cached?.etag;

    final requestUri =
        (_isWeb && _bypassBrowserCache) ? _withCacheBuster(uri) : uri;

    final http.Response response;

    try {
      response = await _client.get(
        requestUri,
        headers: {
          if (validator != null) 'If-None-Match': validator,
        },
      ).timeout(_requestTimeout);
    } on TimeoutException {
      throw const _RepositoryRequestException(
        NetworkFailure(
          'The request timed out. Check your connection and try again.',
        ),
      );
    } catch (_) {
      // Socket errors, TLS errors, ClientException, browser network errors:
      // for a plain GET they all mean "could not reach the server". Catching
      // broadly here (and ONLY around the transport call) is what lets this
      // file avoid importing dart:io.
      throw const _RepositoryRequestException(
        NetworkFailure(
          'Could not connect to the server. Check your internet connection.',
        ),
      );
    }

    final status = response.statusCode;

    if (status == 304) {
      // Unchanged since our ETag: reuse the cached body.
      if (cached != null) return _Response(cached.body, cached.etag);

      throw const _RepositoryRequestException(
        UnknownFailure('The server reported no changes, but nothing is saved.'),
      );
    }

    if (status < 200 || status >= 300) {
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

      throw _RepositoryRequestException(ServerFailure(message, status));
    }

    // http lower-cases header names. On web this is null unless the server
    // exposes the header to JavaScript; that only means "no validator saved".
    return _Response(response.body, response.headers['etag']);
  }

  Uri _withCacheBuster(Uri uri) {
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        kWebCacheBusterParam: '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Parsing (one implementation, shared by network and cache paths)
  // ---------------------------------------------------------------------------

  Page<T> _parsePage<T>(
    String body,
    int currentPage,
    T Function(Map<String, dynamic>) parser,
  ) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      final items = decoded.map((entry) => parser(_toMap(entry))).toList();

      return Page<T>(
        items: List<T>.unmodifiable(items),
        currentPage: 1,
        totalPages: 1,
        hasNext: false,
      );
    }

    if (decoded is Map) {
      final map = _toMap(decoded);
      final rawItems = map['items'];

      if (rawItems is! List) {
        throw const _ShapeException(
          'The API response does not contain a valid items list.',
        );
      }

      final meta =
          map['meta'] is Map ? _toMap(map['meta']) : <String, dynamic>{};
      final links =
          map['links'] is Map ? _toMap(map['links']) : <String, dynamic>{};

      final items = rawItems.map((entry) => parser(_toMap(entry))).toList();

      final current = _toInt(meta['currentPage'], currentPage);
      final total = _toInt(meta['totalPages'], 1);
      final nextLink = links['next']?.toString() ?? '';

      return Page<T>(
        items: List<T>.unmodifiable(items),
        currentPage: current,
        totalPages: total,
        hasNext: nextLink.isNotEmpty || current < total,
      );
    }

    throw const _ShapeException('The API returned an unexpected JSON shape.');
  }

  T _parseSingle<T>(String body, T Function(Map<String, dynamic>) parser) {
    final decoded = jsonDecode(body);

    if (decoded is! Map) {
      throw const _ShapeException('The API returned an unexpected JSON shape.');
    }

    return parser(_toMap(decoded));
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    // A shape problem, NOT a JSON syntax problem: keep them apart so the
    // user-facing message is truthful.
    throw const _ShapeException('Expected a JSON object.');
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class _Response {
  const _Response(this.body, this.etag);

  final String body;
  final String? etag;
}

class _RepositoryRequestException implements Exception {
  const _RepositoryRequestException(this.failure);

  final Failure failure;
}

class _ShapeException implements Exception {
  const _ShapeException(this.message);

  final String message;
}