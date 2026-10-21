class ScheduleModel {
  final String id;
  final String name;
  final double amount;
  final String accountId;
  final String? categoryId;
  final DateTime nextDate;
  final String frequency; // 'monthly', 'weekly', 'yearly', 'bi-weekly'
  final bool isIncome;
  final bool isPaid;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.accountId,
    this.categoryId,
    required this.nextDate,
    required this.frequency,
    this.isIncome = false,
    this.isPaid = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'accountId': accountId,
      'categoryId': categoryId,
      'nextDate': nextDate.toIso8601String(),
      'frequency': frequency,
      'isIncome': isIncome ? 1 : 0,
      'isPaid': isPaid ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      accountId: map['accountId'] as String,
      categoryId: map['categoryId'] as String?,
      nextDate: DateTime.parse(map['nextDate'] as String),
      frequency: map['frequency'] as String,
      isIncome: (map['isIncome'] as int) == 1,
      isPaid: (map['isPaid'] as int) == 1,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt'] as String) 
          : null,
    );
  }

  ScheduleModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? accountId,
    String? categoryId,
    DateTime? nextDate,
    String? frequency,
    bool? isIncome,
    bool? isPaid,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      nextDate: nextDate ?? this.nextDate,
      frequency: frequency ?? this.frequency,
      isIncome: isIncome ?? this.isIncome,
      isPaid: isPaid ?? this.isPaid,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
