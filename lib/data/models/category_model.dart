class CategoryModel {
  final String id;
  final String groupName;
  final String name;
  final double budgeted;
  final double spent;
  final int colorValue;
  final int iconCode;

  const CategoryModel({
    required this.id,
    required this.groupName,
    required this.name,
    required this.budgeted,
    this.spent = 0.0,
    required this.colorValue,
    required this.iconCode,
  });

  double get remaining => budgeted - spent;
  double get progressRatio => budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spent > budgeted;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupName': groupName,
      'name': name,
      'budgeted': budgeted,
      'spent': spent,
      'colorValue': colorValue,
      'iconCode': iconCode,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      groupName: map['groupName'] as String,
      name: map['name'] as String,
      budgeted: (map['budgeted'] as num).toDouble(),
      spent: (map['spent'] as num?)?.toDouble() ?? 0.0,
      colorValue: map['colorValue'] as int,
      iconCode: map['iconCode'] as int,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? groupName,
    String? name,
    double? budgeted,
    double? spent,
    int? colorValue,
    int? iconCode,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      name: name ?? this.name,
      budgeted: budgeted ?? this.budgeted,
      spent: spent ?? this.spent,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
    );
  }
}
