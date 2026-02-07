import 'package:mobile_app/models/campus_profile.dart';
import 'package:mobile_app/models/transaction_record.dart';

class CampusSyncPayload {
  const CampusSyncPayload({
    required this.profile,
    required this.transactions,
    required this.balance,
    required this.balanceUpdatedAt,
  });

  final CampusProfile profile;
  final List<TransactionRecord> transactions;
  final double balance;
  final DateTime balanceUpdatedAt;
}
