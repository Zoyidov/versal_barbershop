part of 'user_management_cubit.dart';

enum UsersStatus { loading, loaded, error }

class UserManagementState extends Equatable {
  final UsersStatus status;
  final List<ManagedUser> users;
  final String? errorMessage;

  /// uid of the row currently mid-action (approve/limit/toggle), so only
  /// that row shows a spinner instead of blocking the whole list.
  final String? busyUid;

  const UserManagementState({
    this.status = UsersStatus.loading,
    this.users = const [],
    this.errorMessage,
    this.busyUid,
  });

  List<ManagedUser> get pending => users.where((u) => !u.isAdmin && !u.approved).toList();
  List<ManagedUser> get approvedBarbers => users.where((u) => !u.isAdmin && u.approved).toList();

  UserManagementState copyWith({
    UsersStatus? status,
    List<ManagedUser>? users,
    String? errorMessage,
    bool clearError = false,
    String? busyUid,
    bool clearBusy = false,
  }) {
    return UserManagementState(
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busyUid: clearBusy ? null : (busyUid ?? this.busyUid),
    );
  }

  @override
  List<Object?> get props => [status, users, errorMessage, busyUid];
}
