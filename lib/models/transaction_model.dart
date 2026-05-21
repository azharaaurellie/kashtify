class TransactionModel {
  final String id;
  final String createdBy;
  final String type; // 'pemasukan' | 'pengeluaran'
  final int amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final String? profileFullName;

  const TransactionModel({
    required this.id,
    required this.createdBy,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
    this.profileFullName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final profiles = map['profiles'];
    return TransactionModel(
      id: map['id'] as String,
      createdBy: map['created_by'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toInt(),
      description: map['description'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      profileFullName:
          profiles != null ? profiles['full_name'] as String? : null,
    );
  }

  bool get isPemasukan => type == 'pemasukan';
}
