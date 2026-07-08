import 'package:equatable/equatable.dart';

/// Shop-wide devsms.uz SMS balance and spend statistics, fetched live from
/// the gateway (not cached in Firestore) so it always reflects the real
/// remaining balance at the moment Settings is opened.
class SmsBalance extends Equatable {
  final int balance;
  final int smsPrice;
  final int totalSms;
  final int totalSpent;
  final int todaySms;
  final int todaySpent;
  final int monthSms;
  final int monthSpent;

  const SmsBalance({
    required this.balance,
    required this.smsPrice,
    required this.totalSms,
    required this.totalSpent,
    required this.todaySms,
    required this.todaySpent,
    required this.monthSms,
    required this.monthSpent,
  });

  @override
  List<Object?> get props => [
        balance,
        smsPrice,
        totalSms,
        totalSpent,
        todaySms,
        todaySpent,
        monthSms,
        monthSpent,
      ];
}
