/// ─── Result Type — Type-safe success/error handling ────────────────
///
/// Replaces try-catch in BLoCs and UseCases with a clean, composable type.
/// Inspired by Kotlin's Result and Rust's Result<T, E>.
///
/// Usage:
///   final result = await createCloneUseCase.call('com.whatsapp');
///   if (result.isSuccess) {
///     final instance = result.data!;
///   } else {
///     final error = result.error!; // AppError with type, message, retryable
///   }
///
library;

import 'app_error.dart';

/// Type-safe result that represents either success (data) or failure (error).
sealed class Result<T> {
  const Result();

  /// Whether this result represents a successful outcome.
  bool get isSuccess => this is Success<T>;

  /// Whether this result represents a failure.
  bool get isError => this is Failure<T>;

  /// The data if success, null if failure.
  T? get data => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };

  /// The error if failure, null if success.
  AppError? get error => switch (this) {
    Success<T>() => null,
    Failure<T>(:final error) => error,
  };

  /// Transform data on success, propagate error on failure.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(:final data) => Success(transform(data)),
    Failure<T>(:final error) => Failure<R>(error),
  };

  /// Execute action on success.
  Result<T> onSuccess(void Function(T data) action) {
    if (isSuccess) action(data as T);
    return this;
  }

  /// Execute action on failure.
  Result<T> onError(void Function(AppError error) action) {
    if (isError) action(error!);
    return this;
  }

  /// Get data or throw error (for when you MUST have data).
  T getOrThrow() => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>(:final error) => throw error,
  };

  /// Get data or fallback value.
  T getOrDefault(T defaultValue) => data ?? defaultValue;

  /// Convert to async Result (for chaining).
  Future<Result<R>> asyncMap<R>(Future<R> Function(T data) transform) => switch (this) {
    Success<T>(:final data) => transform(data).then((r) => Success<R>(r)).catchError(
      (e) => Failure<R>(AppError.unknown(e.toString())),
    ),
    Failure<T>(:final error) => Future.value(Failure<R>(error)),
  };

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
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Failure result containing error.
final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';
}
