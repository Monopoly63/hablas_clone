/// ─── Result Type — Type-safe success/error handling ────────────────
///
/// v2.0.0 FIX: Changed from `sealed class` to `abstract class` because
/// `sealed class` with pattern matching caused AOT compilation failures.
/// This simpler implementation is compatible with all Dart SDK versions
/// and all compilation modes (JIT, AOT, release).
///
library;

import 'app_error.dart';

/// Type-safe result that represents either success (data) or failure (error).
abstract class Result<T> {
  const Result();

  /// Whether this result represents a successful outcome.
  bool get isSuccess => this is Success<T>;

  /// Whether this result represents a failure.
  bool get isError => this is Failure<T>;

  /// The data if success, null if failure.
  T? get data {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }

  /// The error if failure, null if success.
  AppError? get error {
    if (this is Failure<T>) {
      return (this as Failure<T>).error;
    }
    return null;
  }

  /// Transform data on success, propagate error on failure.
  Result<R> map<R>(R Function(T data) transform) {
    if (this is Success<T>) {
      return Success<R>(transform((this as Success<T>).data));
    }
    return Failure<R>((this as Failure<T>).error);
  }

  /// Execute action on success.
  Result<T> onSuccess(void Function(T data) action) {
    if (isSuccess && data != null) action(data as T);
    return this;
  }

  /// Execute action on failure.
  Result<T> onError(void Function(AppError error) action) {
    if (isError && error != null) action(error!);
    return this;
  }

  /// Get data or throw error.
  T getOrThrow() {
    if (this is Success<T>) return (this as Success<T>).data;
    throw (this as Failure<T>).error;
  }

  /// Get data or fallback value.
  T getOrDefault(T defaultValue) => data ?? defaultValue;

  /// Factory: Create success result.
  static Result<T> ok<T>(T data) => Success(data);

  /// Factory: Create failure result.
  static Result<T> fail<T>(AppError error) => Failure<T>(error);

  /// Factory: Wrap a try-catch block.
  static Result<T> guard<T>(T Function() fn) {
    try {
      return Success(fn());
    } on AppError catch (e) {
      return Failure<T>(e);
    } catch (e) {
      return Failure<T>(AppError.unknown(e.toString()));
    }
  }

  /// Factory: Wrap an async try-catch block.
  static Future<Result<T>> guardAsync<T>(Future<T> Function() fn) async {
    try {
      return Success(await fn());
    } on AppError catch (e) {
      return Failure<T>(e);
    } catch (e) {
      return Failure<T>(AppError.unknown(e.toString()));
    }
  }
}

/// Success result containing data.
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Failure result containing error.
class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';
}
