import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/app_state_service.dart';
import '../../../core/error/result.dart';
import '../../../core/error/app_error.dart';
import '../domain/auth_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckLockStatus extends AuthEvent {}

class VerifyPin extends AuthEvent {
  final String pin;
  VerifyPin(this.pin);
  @override
  List<Object?> get props => [pin];
}

class SetPin extends AuthEvent {
  final String pin;
  SetPin(this.pin);
  @override
  List<Object?> get props => [pin];
}

class RemovePin extends AuthEvent {}

class EnableBiometric extends AuthEvent {
  final bool enabled;
  EnableBiometric(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class ResetAuth extends AuthEvent {}

// ─── State ───────────────────────────────────────────────────────────────

class AuthState extends Equatable {
  final bool isLocked;
  final bool isLockEnabled;
  final bool hasPin;
  final bool biometricEnabled;
  final bool isVerified;
  final String? error;
  final int failedAttempts;

  const AuthState({
    this.isLocked = true,
    this.isLockEnabled = false,
    this.hasPin = false,
    this.biometricEnabled = false,
    this.isVerified = false,
    this.error,
    this.failedAttempts = 0,
  });

  AuthState copyWith({
    bool? isLocked,
    bool? isLockEnabled,
    bool? hasPin,
    bool? biometricEnabled,
    bool? isVerified,
    String? error,
    int? failedAttempts,
  }) => AuthState(
    isLocked: isLocked ?? this.isLocked,
    isLockEnabled: isLockEnabled ?? this.isLockEnabled,
    hasPin: hasPin ?? this.hasPin,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    isVerified: isVerified ?? this.isVerified,
    error: error,
    failedAttempts: failedAttempts ?? this.failedAttempts,
  );

  @override
  List<Object?> get props => [isLocked, isLockEnabled, hasPin, biometricEnabled, isVerified, failedAttempts];
}

// ─── BLoC ────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final SecurityService _security = sl<SecurityService>();

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState()) {
    on<CheckLockStatus>(_onCheckLockStatus);
    on<VerifyPin>(_onVerifyPin);
    on<SetPin>(_onSetPin);
    on<RemovePin>(_onRemovePin);
    on<EnableBiometric>(_onEnableBiometric);
    on<ResetAuth>(_onResetAuth);
  }

  Future<void> _onCheckLockStatus(CheckLockStatus event, Emitter<AuthState> emit) async {
    final lockEnabled = await _security.isLockEnabled();
    final hasPin = await _security.hasPin();
    final biometricEnabled = await _security.isBiometricEnabled();
    final failedAttempts = await _security.getFailedAttempts();

    emit(state.copyWith(
      isLockEnabled: lockEnabled,
      hasPin: hasPin,
      biometricEnabled: biometricEnabled,
      isLocked: lockEnabled && !state.isVerified,
      failedAttempts: failedAttempts,
    ));
  }

  Future<void> _onVerifyPin(VerifyPin event, Emitter<AuthState> emit) async {
    final result = await _security.verifyPin(event.pin);
    final attempts = await _security.getFailedAttempts();

    if (result.isSuccess && result.data == true) {
      emit(state.copyWith(
        isVerified: true,
        isLocked: false,
        failedAttempts: 0,
        error: null,
      ));
    } else if (result.isSuccess && result.data == false) {
      emit(state.copyWith(
        isVerified: false,
        failedAttempts: attempts,
        error: attempts >= 5 ? 'Too many attempts. Please wait.' : 'Wrong PIN. Try again.',
      ));
    } else {
      // Error (integrity violation, etc.)
      emit(state.copyWith(
        isVerified: false,
        failedAttempts: attempts,
        error: result.error?.displayMessage ?? 'Verification failed',
      ));
    }
  }

  Future<void> _onSetPin(SetPin event, Emitter<AuthState> emit) async {
    final result = await _security.setPin(event.pin);

    if (result.isSuccess) {
      await sl<AppStateService>().setLockEnabled(true);
      emit(state.copyWith(
        hasPin: true,
        isLockEnabled: true,
        isVerified: true,
        isLocked: false,
        error: null,
      ));
    } else {
      emit(state.copyWith(error: result.error?.displayMessage ?? 'Failed to set PIN'));
    }
  }

  Future<void> _onRemovePin(RemovePin event, Emitter<AuthState> emit) async {
    final result = await _security.removePin();

    if (result.isSuccess) {
      await sl<AppStateService>().setLockEnabled(false);
      emit(state.copyWith(
        hasPin: false,
        isLockEnabled: false,
        isVerified: true,
        isLocked: false,
      ));
    }
  }

  Future<void> _onEnableBiometric(EnableBiometric event, Emitter<AuthState> emit) async {
    final result = await _security.setBiometricEnabled(event.enabled);
    if (result.isSuccess) {
      emit(state.copyWith(biometricEnabled: event.enabled));
    }
  }

  Future<void> _onResetAuth(ResetAuth event, Emitter<AuthState> emit) async {
    emit(const AuthState());
    add(CheckLockStatus());
  }
}
