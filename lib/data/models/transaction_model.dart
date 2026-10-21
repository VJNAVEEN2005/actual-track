class TransactionModel {
  final String id;
  final DateTime date;
  final String payee;
  final double amount;
  final String accountId;
  final String? categoryId;
  final String? notes;
  final bool isIncome;
  final bool isCleared; // Actual Budget reconciliation state

  const TransactionModel({
    required this.id,
    required this.date,
    required this.payee,
    required this.amount,
    required this.accountId,
    this.categoryId,
    this.notes,
    this.isIncome = false,
    this.isCleared = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'payee': payee,
      'amount': amount,
      'accountId': accountId,
      'categoryId': categoryId,
      'notes': notes,
      'isIncome': isIncome ? 1 : 0,
      'isCleared': isCleared ? 1 : 0,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      payee: map['payee'] as String,
      amount: (map['amount'] as num).toDouble(),
      accountId: map['accountId'] as String,
      categoryId: map['categoryId'] as String?,
      notes: map['notes'] as String?,
      isIncome: (map['isIncome'] as int) == 1,
      isCleared: (map['isCleared'] as int?) == 1 || map['isCleared'] == null,
    );
  }

  TransactionModel copyWith({
    String? id,
    DateTime? date,
    String? payee,
    double? amount,
    String? accountId,
    String? categoryId,
    String? notes,
    bool? isIncome,
    bool? isCleared,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      payee: payee ?? this.payee,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      isIncome: isIncome ?? this.isIncome,
      isCleared: isCleared ?? this.isCleared,
    );
  }
}
