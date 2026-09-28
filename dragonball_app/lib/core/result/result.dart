// lib/core/result/result.dart
import 'package:meta/meta.dart';
import '../errors/failure.dart';

@immutable
sealed class Result<S, F extends Failure> {
  const Result();

  bool get isSuccess => this is Ok<S, F>;
  bool get isFailure => this is Err<S, F>;
}

final class Ok<S, F extends Failure> extends Result<S, F> {
  final S value;
  const Ok(this.value);
}

final class Err<S, F extends Failure> extends Result<S, F> {
  final F failure;
  const Err(this.failure);
}