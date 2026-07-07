import 'package:equatable/equatable.dart';

/// A single month's visit/cancellation bucket for one client, used on the
/// client detail breakdown screen. [monthKey] is a stable `yyyy-MM` string.
class MonthlyStat extends Equatable {
  final String monthKey;
  final int visits;
  final int cancellations;

  const MonthlyStat({
    required this.monthKey,
    required this.visits,
    required this.cancellations,
  });

  @override
  List<Object?> get props => [monthKey, visits, cancellations];
}
