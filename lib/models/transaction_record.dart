class TransactionRecord {
  const TransactionRecord({
    required this.sid,
    required this.txnId,
    required this.amount,
    required this.balance,
    required this.occurredAt,
    required this.occurredDay,
    required this.itemName,
    required this.rawPayload,
  });

  final String sid;
  final String txnId;
  final double amount;
  final double? balance;
  final String occurredAt;
  final String occurredDay;
  final String itemName;
  final String rawPayload;

  Map<String, Object?> toDbMap() {
    return <String, Object?>{
      'sid': sid,
      'txn_id': txnId,
      'amount': amount,
      'balance': balance,
      'occurred_at': occurredAt,
      'occurred_day': occurredDay,
      'item_name': itemName,
      'raw_payload': rawPayload,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory TransactionRecord.fromDbMap(Map<String, Object?> map) {
    return TransactionRecord(
      sid: (map['sid'] ?? '').toString(),
      txnId: (map['txn_id'] ?? '').toString(),
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      balance: map['balance'] == null
          ? null
          : ((map['balance'] ?? 0) as num).toDouble(),
      occurredAt: (map['occurred_at'] ?? '').toString(),
      occurredDay: (map['occurred_day'] ?? '').toString(),
      itemName: (map['item_name'] ?? '').toString(),
      rawPayload: (map['raw_payload'] ?? '').toString(),
    );
  }
}
