part of 'settings_cubit.dart';

enum SettingsStatus { loading, loaded, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final AppSettings settings;
  final bool saving;
  final String? errorMessage;
  final bool saved;

  const SettingsState({
    this.status = SettingsStatus.loading,
    this.settings = AppSettings.fallback,
    this.saving = false,
    this.errorMessage,
    this.saved = false,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
    bool? saved,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saved: saved ?? false,
    );
  }

  @override
  List<Object?> get props => [status, settings, saving, errorMessage, saved];
}
