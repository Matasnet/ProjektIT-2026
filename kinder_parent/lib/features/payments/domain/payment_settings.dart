import 'package:equatable/equatable.dart';

/// Ustawienia opłaty – dokument settings/payments (zmienia admin w panelu).
class PaymentSettings extends Equatable {
  final int monthlyFee;
  final int dueDay;
  final String recipient;
  final String accountNumber;

  const PaymentSettings({
    required this.monthlyFee,
    required this.dueDay,
    required this.recipient,
    required this.accountNumber,
  });

  factory PaymentSettings.fromMap(Map<String, dynamic> data) {
    return PaymentSettings(
      monthlyFee: (data['monthlyFee'] as num? ?? 0).round(),
      dueDay: (data['dueDay'] as num? ?? 10).round(),
      recipient: (data['recipient'] ?? '') as String,
      accountNumber: (data['accountNumber'] ?? '') as String,
    );
  }

  /// Termin płatności w danym miesiącu (do końca dnia)
  DateTime dueDate(DateTime month) =>
      DateTime(month.year, month.month, dueDay, 23, 59);

  @override
  List<Object?> get props => [monthlyFee, dueDay, recipient, accountNumber];
}
