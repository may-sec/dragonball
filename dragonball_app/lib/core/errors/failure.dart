import 'package:meta/meta.dart';

// @immutable tells the Dart analyzer that this class and all its subclasses cannot have mutable fields.
// Every property must be final, guaranteeing thread safety and eliminating accidental state mutation.
@immutable

// 'sealed' (Dart 3 feature):
// 1. Prevents any code outside of this file from extending, implementing, or subclassing Result.
// 2. Gives the Dart compiler exhaustive pattern matching guarantees—meaning in a `switch (result)`,
sealed class Failure {
  final String message;
  const Failure(this.message);
}


// switch (failure) {
//   case NetworkFailure(): // Handled
//   case ServerFailure():  // Handled
//   case ParseFailure():   // Handled
// }
// No `default:` case needed; compiler enforces full coverage.


// 'final class' (Dart 3 feature):
// Ensures this class cannot be extended, implemented, or mixed in by any other class (even inside this file).
// It locks down the implementation entirely so the design remains immutable and predictable.
final class NetworkFailure extends Failure{
  const NetworkFailure(super.message);
}

final class ServerFailure extends Failure{
  final int? statusCode;
  const ServerFailure(super.message, [this.statusCode]); //Optional Positional Parameters
}

// Represents serialization, deserialization, JSON format mismatch,
// or schema casting failures.
final class ParseFailure extends Failure{
  const ParseFailure(super.message);
}
