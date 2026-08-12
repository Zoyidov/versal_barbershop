import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../services/push_notification_service.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_barber_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/delete_account_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/watch_barber_profile_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

import '../../features/admin/data/datasources/admin_remote_data_source.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/approve_barber_usecase.dart';
import '../../features/admin/domain/usecases/set_sms_limit_usecase.dart';
import '../../features/admin/domain/usecases/set_user_active_usecase.dart';
import '../../features/admin/domain/usecases/update_barber_schedule_usecase.dart';
import '../../features/admin/domain/usecases/watch_users_usecase.dart';
import '../../features/admin/presentation/cubit/pending_approval_cubit.dart';
import '../../features/admin/presentation/cubit/user_management_cubit.dart';

import '../../features/appointments/data/datasources/appointment_remote_data_source.dart';
import '../../features/appointments/data/repositories/appointment_repository_impl.dart';
import '../../features/appointments/domain/repositories/appointment_repository.dart';
import '../../features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import '../../features/appointments/domain/usecases/create_appointment_usecase.dart';
import '../../features/appointments/domain/usecases/get_client_history_usecase.dart';
import '../../features/appointments/domain/usecases/update_appointment_usecase.dart';
import '../../features/appointments/domain/usecases/watch_appointment_counts_for_range_usecase.dart';
import '../../features/appointments/domain/usecases/watch_appointments_for_day_usecase.dart';
import '../../features/appointments/presentation/cubit/appointment_form_cubit.dart';
import '../../features/appointments/presentation/cubit/dashboard_cubit.dart';

import '../../features/statistics/data/datasources/statistics_remote_data_source.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/get_client_monthly_breakdown_usecase.dart';
import '../../features/statistics/domain/usecases/get_client_visits_usecase.dart';
import '../../features/statistics/domain/usecases/search_clients_usecase.dart';
import '../../features/statistics/domain/usecases/watch_client_stats_usecase.dart';
import '../../features/statistics/presentation/cubit/client_detail_cubit.dart';
import '../../features/statistics/presentation/cubit/client_search_cubit.dart';
import '../../features/statistics/presentation/cubit/statistics_cubit.dart';

import '../../features/public_booking/data/datasources/public_booking_remote_data_source.dart';
import '../../features/public_booking/data/repositories/public_booking_repository_impl.dart';
import '../../features/public_booking/domain/repositories/public_booking_repository.dart';
import '../../features/public_booking/domain/usecases/create_public_booking_usecase.dart';
import '../../features/public_booking/domain/usecases/get_public_barbers_usecase.dart';
import '../../features/public_booking/domain/usecases/get_public_day_slots_usecase.dart';
import '../../features/public_booking/presentation/cubit/public_booking_cubit.dart';

import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_sms_balance_usecase.dart';
import '../../features/settings/domain/usecases/update_reminder_window_usecase.dart';
import '../../features/settings/domain/usecases/update_schedule_hours_usecase.dart';
import '../../features/settings/domain/usecases/watch_settings_usecase.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';

/// Global service locator. Kept intentionally simple (get_it) rather than
/// pulling in a code-gen DI framework — this app's dependency graph is
/// small and static, so a hand-registered locator is easier to read and
/// modify than generated injector code.
final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---- Firebase SDK instances (singletons) ----
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFunctions>(
    () => FirebaseFunctions.instanceFor(region: 'us-central1'),
  );
  sl.registerLazySingleton(() => PushNotificationService(firestore: sl()));

  // ---- Auth feature ----
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(auth: sl(), functions: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentBarberUseCase(sl()));
  sl.registerLazySingleton(() => WatchBarberProfileUseCase(sl()));
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      deleteAccountUseCase: sl(),
      getCurrentBarberUseCase: sl(),
      authRepository: sl(),
      pushNotificationService: sl(),
    ),
  );

  // ---- Admin feature (user approval + SMS limits; admin-only) ----
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(firestore: sl(), functions: sl()),
  );
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => WatchUsersUseCase(sl()));
  sl.registerLazySingleton(() => ApproveBarberUseCase(sl()));
  sl.registerLazySingleton(() => SetSmsLimitUseCase(sl()));
  sl.registerLazySingleton(() => SetUserActiveUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBarberScheduleUseCase(sl()));
  sl.registerFactory(
    () => UserManagementCubit(
      watchUsersUseCase: sl(),
      approveBarberUseCase: sl(),
      setSmsLimitUseCase: sl(),
      setUserActiveUseCase: sl(),
      updateBarberScheduleUseCase: sl(),
    ),
  );
  // Provided once above `RootShell` (see app.dart's `_AuthGate`) so the
  // bottom-nav badge and the Settings-page "Foydalanuvchilar" row badge
  // share the same count instead of each opening their own listener.
  // `enabled` is the signed-in user's `isAdmin` flag at provide-time.
  sl.registerFactoryParam<PendingApprovalCubit, bool, void>(
    (enabled, _) => PendingApprovalCubit(watchUsersUseCase: sl(), enabled: enabled),
  );

  // ---- Appointments feature ----
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
    () => AppointmentRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => WatchAppointmentsForDayUseCase(sl()));
  sl.registerLazySingleton(() => WatchAppointmentCountsForRangeUseCase(sl()));
  sl.registerLazySingleton(() => CreateAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => CancelAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => GetClientHistoryUseCase(sl()));
  sl.registerFactory(
    () => DashboardCubit(
      watchAppointmentsForDayUseCase: sl(),
      watchAppointmentCountsForRangeUseCase: sl(),
      cancelAppointmentUseCase: sl(),
      watchSettingsUseCase: sl(),
      watchBarberProfileUseCase: sl(),
      barberId: sl<FirebaseAuth>().currentUser?.uid,
    ),
  );
  // Separate named instance for the admin cross-barber schedule view
  // (`AdminSchedulePage`), which starts unscoped (barberId: null -> "every
  // barber") and switches barber via `DashboardCubit.setBarberId` from a
  // picker, instead of being pinned to the caller's own uid.
  sl.registerFactory(
    () => DashboardCubit(
      watchAppointmentsForDayUseCase: sl(),
      watchAppointmentCountsForRangeUseCase: sl(),
      cancelAppointmentUseCase: sl(),
      watchSettingsUseCase: sl(),
      watchBarberProfileUseCase: sl(),
    ),
    instanceName: 'adminSchedule',
  );
  sl.registerFactory(
    () => AppointmentFormCubit(
      createAppointmentUseCase: sl(),
      updateAppointmentUseCase: sl(),
      getClientHistoryUseCase: sl(),
      cancelAppointmentUseCase: sl(),
      searchClientsUseCase: sl(),
    ),
  );

  // ---- Statistics feature ----
  sl.registerLazySingleton<StatisticsRemoteDataSource>(
    () => StatisticsRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<StatisticsRepository>(
    () => StatisticsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => WatchClientStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetClientMonthlyBreakdownUseCase(sl()));
  sl.registerLazySingleton(() => GetClientVisitsUseCase(sl()));
  sl.registerLazySingleton(() => SearchClientsUseCase(sl()));
  // Both take the caller's scope as a runtime param (the signed-in
  // barber's own uid, or null for an admin's "every barber" view) rather
  // than a fixed DI-time value, since which barber it is is only known
  // once the page reads AuthCubit's live state.
  sl.registerFactoryParam<StatisticsCubit, String?, void>(
    (barberId, _) => StatisticsCubit(watchClientStatsUseCase: sl(), barberId: barberId),
  );
  sl.registerFactoryParam<ClientSearchCubit, String?, void>(
    (barberId, _) => ClientSearchCubit(searchClientsUseCase: sl(), barberId: barberId),
  );
  sl.registerFactory(
    () => ClientDetailCubit(
      getClientMonthlyBreakdownUseCase: sl(),
      getClientVisitsUseCase: sl(),
    ),
  );

  // ---- Public booking feature (no auth; client self-service screen) ----
  sl.registerLazySingleton<PublicBookingRemoteDataSource>(
    () => PublicBookingRemoteDataSourceImpl(functions: sl()),
  );
  sl.registerLazySingleton<PublicBookingRepository>(
    () => PublicBookingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetPublicBarbersUseCase(sl()));
  sl.registerLazySingleton(() => GetPublicDaySlotsUseCase(sl()));
  sl.registerLazySingleton(() => CreatePublicBookingUseCase(sl()));
  sl.registerFactory(
    () => PublicBookingCubit(
      getBarbersUseCase: sl(),
      getDaySlotsUseCase: sl(),
      createBookingUseCase: sl(),
    ),
  );

  // ---- Settings feature ----
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(firestore: sl(), functions: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => WatchSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateReminderWindowUseCase(sl()));
  sl.registerLazySingleton(() => UpdateScheduleHoursUseCase(sl()));
  sl.registerLazySingleton(() => GetSmsBalanceUseCase(sl()));
  sl.registerFactory(
    () => SettingsCubit(
      watchSettingsUseCase: sl(),
      updateReminderWindowUseCase: sl(),
      updateScheduleHoursUseCase: sl(),
      getSmsBalanceUseCase: sl(),
    ),
  );
}
