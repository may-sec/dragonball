import 'package:flutter/foundation.dart';

import '../errors/failure.dart';

@immutable
sealed class Result<S, F extends Failure> {
  const Result();

  bool get isSuccess => this is Ok<S, F>;

  bool get isFailure => this is Err<S, F>;

  R fold<R>({
    required R Function(S value) onSuccess,
    required R Function(F failure) onFailure,
  }) {
    return switch (this) {
      Ok<S, F>(:final value) => onSuccess(value),
      Err<S, F>(:final failure) => onFailure(failure),
    };
  }
}

final class Ok<S, F extends Failure> extends Result<S, F> {
  const Ok(this.value);

  final S value;
}

final class Err<S, F extends Failure> extends Result<S, F> {
  const Err(this.failure);

  final F failure;
}