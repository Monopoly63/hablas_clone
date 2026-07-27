/// ─── Result Type — Simple success/error handling ──────────────────
///
/// MAXIMUM COMPATIBILITY: Uses only simple boolean flag + data/error.
/// No sealed classes, no pattern matching, no type switching.
/// Works in ALL compilation modes: JIT, AOT, release, debug.
///
library;

import 'app_error.dart';

/// Simple result type that represents either success or failure.
class Result<T> {
  final bool _isSuccess;
  final T? _data;
  final AppError? _error;

  const Result._({required bool isSuccess, T? data, AppError? error})
      : _isSuccess = isSuccess, _data = data, _error = error;

  /// Whether this result represents a successful outcome.
  bool get isSuccess => _isSuccess;

  /// Whether this result represents a failure.
  bool get isError => !_isSuccess;

  /// The data if success, null if failure.
  T? get data => _data;

  /// The error if failure, null if success.
  AppError? get error => _error;

  /// Transform data on success, propagate error on failure.
  Result<R> map<R>(R Function(T data) transform) {
    if (_isSuccess && _data != null) {
      return Result._(isSuccess: true, data: transform(_data!));
    }
    return Result._(isSuccess: false, error: _error);
  }

  /// Get data or throw error.
  T getOrThrow() {
    if (_isSuccess) return _data!;
    throw _error ?? AppError.unknown('Unknown error');
  }

  /// Get data or fallback value.
  T getOrDefault(T defaultValue) => _data ?? defaultValue;

  /// Factory: Create success result.
  static Result<T> ok<T>(T data) => Result._(isSuccess: true, data: data);

  /// Factory: Create failure result.
  static Result<T> fail<T>(AppError error) => Result._(isSuccess: false, error: error);

  /// Factory: Wrap a try-catch block.
  static Result<T> guard<T>(T Function() fn) {
    try {
      return Result._(isSuccess: true, data: fn());
    } on AppError catch (e) {
      return Result._(isSuccess: false, error: e);
    } catch (e) {
      return Result._(isSuccess: false, error: AppError.unknown(e.toString()));
    }
  }

  /// Factory: Wrap an async try-catch block.
  static Future<Result<T>> guardAsync<T>(Future<T> Function() fn) async {
    try {
      return Result._(isSuccess: true, data: await fn());
    } on AppError catch (e) {
      return Result._(isSuccess: false, error: e);
    } catch (e) {
      return Result._(isSuccess: false, error: AppError.unknown(e.toString()));
    }
  }

  @override
  String toString() => _isSuccess ? 'Success($_data)' : 'Failure($_error)';
}
