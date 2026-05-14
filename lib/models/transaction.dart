enum TransactionType { recharge, payment, refund, withdrawal }
enum TransactionStatus { pending, approved, rejected }

class AppTransaction {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String referenceNumber; // Transfer ID or Payment Code
  final DateTime timestamp;
  final String? note; // Optional reason or payment details

  AppTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.referenceNumber,
    this.note,
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
      'note': note,
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
      note: map['note'],
    );
  }
}
