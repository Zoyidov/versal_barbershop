part of 'settings_cubit.dart';

enum SettingsStatus { loading, loaded, error }

/// Which of the settings forms most recently completed a save — lets the
/// UI show a save confirmation specific to that form instead of a single
/// generic (and potentially mismatched) message.
enum SettingsSaveTarget { reminderWindow, scheduleHours }

enum SmsBalanceStatus { idle, loading, loaded, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final AppSettings settings;
  final bool saving;
  final String? errorMessage;
  final bool saved;
  final SettingsSaveTarget? savedTarget;
  final SmsBalanceStatus smsBalanceStatus;
  final SmsBalance? smsBalance;
  final String? smsBalanceError;

  const SettingsState({
    this.status = SettingsStatus.loading,
    this.settings = AppSettings.fallback,
    this.saving = false,
    this.errorMessage,
    this.saved = false,
    this.savedTarget,
    this.smsBalanceStatus = SmsBalanceStatus.idle,
    this.smsBalance,
    this.smsBalanceError,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
    bool? saved,
    SettingsSaveTarget? savedTarget,
    SmsBalanceStatus? smsBalanceStatus,
    SmsBalance? smsBalance,
    String? smsBalanceError,
    bool clearSmsBalanceError = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saved: saved ?? false,
      savedTarget: saved == true ? savedTarget : null,
      smsBalanceStatus: smsBalanceStatus ?? this.smsBalanceStatus,
      smsBalance: smsBalance ?? this.smsBalance,
      smsBalanceError: clearSmsBalanceError ? null : (smsBalanceError ?? this.smsBalanceError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        settings,
        saving,
        errorMessage,
        saved,
        savedTarget,
        smsBalanceStatus,
        smsBalance,
        smsBalanceError,
      ];
}
