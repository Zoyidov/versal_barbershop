import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/managed_user.dart';
import '../../domain/usecases/watch_users_usecase.dart';

/// Lightweight, admin-only count of barbers awaiting approval - drives the
/// small badge on the "Sozlamalar" bottom-nav tab and the "Foydalanuvchilar"
/// row inside it (see `RootShell`/`SettingsPage`). Kept separate from the
/// heavier `UserManagementCubit` (full CRUD for the Users screen) so this
/// cheap, always-alive count doesn't rebuild on every busy/error field that
/// cubit tracks, and so a non-admin never opens a `users` collection
/// listener it has no permission to read anyway (`enabled: false` skips it
/// entirely, matching `firestore.rules`, which restricts listing every
/// user to admins).
class PendingApprovalCubit extends Cubit<int> {
  final WatchUsersUseCase _watchUsersUseCase;
  StreamSubscription<List<ManagedUser>>? _subscription;

  PendingApprovalCubit({
    required WatchUsersUseCase watchUsersUseCase,
    required bool enabled,
  })  : _watchUsersUseCase = watchUsersUseCase,
        super(0) {
    if (enabled) _subscribe();
  }

  void _subscribe() {
    _subscription = _watchUsersUseCase().listen((users) {
      emit(users.where((u) => !u.isAdmin && !u.approved).length);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
