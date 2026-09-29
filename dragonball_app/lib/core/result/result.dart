// lib/core/result/result.dart
import 'package:meta/meta.dart';
import '../errors/failure.dart';

@immutable

//Callers can easily forget to handle errors, leading to unhandled runtime exceptions.
//Functions have hidden control flows (an exception interrupts execution jumps up the call stack).

sealed class Result<S, F extends Failure> {
  const Result();

  // Boolean helper getter returning true if the current instance is an Ok<S, F> variant.
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




// Pattern matching with switch expression:
// final message = switch (result) {
//   Ok(:final value) => 'Loaded ${value.name}',
//   Err(:final failure) => 'Error: ${failure.message}',
// };

// // Pattern matching with if-case:
// if (result case Ok(:final value)) {
//   print('Successfully parsed: $value');
// } else if (result case Err(:final failure)) {
//   print('Failed with code: ${failure.message}');
// }