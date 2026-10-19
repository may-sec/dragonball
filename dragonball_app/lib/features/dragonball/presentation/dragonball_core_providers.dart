import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors/failure.dart';
import '../data/dragonball_repository.dart';

// LEARN (breaking import cycles): these three things used to live in
// dragonball_notifier.dart. The new catalog provider needs them, and the
// notifier needs the catalog provider. Putting the shared pieces in a small
// file BELOW both removes the cycle. dragonball_notifier.dart re-exports this
// file, so every existing `import 'dragonball_notifier.dart'` keeps working.

final networkNoticeProvider =
    NotifierProvider<NetworkNoticeController, String?>(
  NetworkNoticeController.new,
);

class NetworkNoticeController extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) {
    state = message;
  }

  void clear() {
    state = null;
  }
}

final dragonBallRepositoryProvider = Provider<DragonBallRepository>((ref) {
  final client = http.Client();

  ref.onDispose(client.close);

  return DragonBallRepository(client);
});

final class DragonBallRequestException implements Exception {
  const DragonBallRequestException(this.failure);

  final Failure failure;

  @override
  String toString() => failure.message;
}