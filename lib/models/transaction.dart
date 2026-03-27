enum TransactionType { recharge, payment, refund }
enum TransactionStatus { pending, approved, rejected }

class AppTransaction {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String referenceNumber; // Transfer ID or Payment Code
  final DateTime timestamp;

  AppTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.referenceNumber,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.index,
      'status': status.index,
      'referenceNumber': referenceNumber,
      'timestamp': timestamp,
    };
  }

  factory AppTransaction.fromMap(Map<String, dynamic> map, String docId) {
    return AppTransaction(
      id: docId,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: TransactionType.values[map['type'] ?? 0],
      status: TransactionStatus.values[map['status'] ?? 0],
      referenceNumber: map['referenceNumber'] ?? '',
      timestamp: (map['timestamp'] as dynamic).toDate(),
    );
  }
}
