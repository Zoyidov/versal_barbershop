import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_barber_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

import '../../features/appointments/data/datasources/appointment_remote_data_source.dart';
import '../../features/appointments/data/repositories/appointment_repository_impl.dart';
import '../../features/appointments/domain/repositories/appointment_repository.dart';
import '../../features/appointments/domain/usecases/cancel_appointment_usecase.dart';
import '../../features/appointments/domain/usecases/create_appointment_usecase.dart';
import '../../features/appointments/domain/usecases/get_client_history_usecase.dart';
import '../../features/appointments/domain/usecases/update_appointment_usecase.dart';
import '../../features/appointments/domain/usecases/watch_appointments_for_day_usecase.dart';
import '../../features/appointments/presentation/cubit/appointment_form_cubit.dart';
import '../../features/appointments/presentation/cubit/dashboard_cubit.dart';

import '../../features/statistics/data/datasources/statistics_remote_data_source.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/get_client_monthly_breakdown_usecase.dart';
import '../../features/statistics/domain/usecases/watch_client_stats_usecase.dart';
import '../../features/statistics/presentation/cubit/client_detail_cubit.dart';
import '../../features/statistics/presentation/cubit/statistics_cubit.dart';

import '../../features/settings/data/datasources/settings_remote_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/update_reminder_window_usecase.dart';
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

  // ---- Auth feature ----
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(auth: sl(), functions: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentBarberUseCase(sl()));
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentBarberUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ---- Appointments feature ----
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
    () => AppointmentRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => WatchAppointmentsForDayUseCase(sl()));
  sl.registerLazySingleton(() => CreateAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => CancelAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => GetClientHistoryUseCase(sl()));
  sl.registerFactory(
    () => DashboardCubit(watchAppointmentsForDayUseCase: sl(), cancelAppointmentUseCase: sl()),
  );
  sl.registerFactory(
    () => AppointmentFormCubit(
      createAppointmentUseCase: sl(),
      updateAppointmentUseCase: sl(),
      getClientHistoryUseCase: sl(),
      cancelAppointmentUseCase: sl(),
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
  sl.registerFactory(() => StatisticsCubit(watchClientStatsUseCase: sl()));
  sl.registerFactory(
    () => ClientDetailCubit(getClientMonthlyBreakdownUseCase: sl()),
  );

  // ---- Settings feature ----
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => WatchSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateReminderWindowUseCase(sl()));
  sl.registerFactory(
    () => SettingsCubit(watchSettingsUseCase: sl(), updateReminderWindowUseCase: sl()),
  );
}
