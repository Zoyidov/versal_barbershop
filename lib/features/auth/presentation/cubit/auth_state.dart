part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final Barber? barber;
  final bool submitting;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.barber,
    this.submitting = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    Barber? barber,
    bool clearBarber = false,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      barber: clearBarber ? null : (barber ?? this.barber),
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, barber, submitting, errorMessage];
}
