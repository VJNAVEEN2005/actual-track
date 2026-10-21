class AccountModel {
  final String id;
  final String name;
  final String type; // 'checking', 'savings', 'credit', 'investment', 'cash'
  final double balance;
  final int colorValue;
  final int iconCode;
  final bool isOffBudget;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.colorValue,
    required this.iconCode,
    this.isOffBudget = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'colorValue': colorValue,
      'iconCode': iconCode,
      'isOffBudget': isOffBudget ? 1 : 0,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
      colorValue: map['colorValue'] as int,
      iconCode: map['iconCode'] as int,
      isOffBudget: (map['isOffBudget'] as int) == 1,
    );
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    int? colorValue,
    int? iconCode,
    bool? isOffBudget,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
      isOffBudget: isOffBudget ?? this.isOffBudget,
    );
  }
}
