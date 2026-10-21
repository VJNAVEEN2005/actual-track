enum OpenUiActionStatus {
  pending,
  confirmed,
  cancelled,
}

abstract class OpenUiNode {
  final String id;
  const OpenUiNode({required this.id});
}

class OpenUiMetricNode extends OpenUiNode {
  final String label;
  final String value;
  final String? badge;
  final String? icon;

  const OpenUiMetricNode({
    required super.id,
    required this.label,
    required this.value,
    this.badge,
    this.icon,
  });
}

class OpenUiLineChartNode extends OpenUiNode {
  final String title;
  final String? type; // 'cashflow'
  final List<double>? inflowSpots;
  final List<double>? outflowSpots;

  const OpenUiLineChartNode({
    required super.id,
    required this.title,
    this.type = 'cashflow',
    this.inflowSpots,
    this.outflowSpots,
  });
}

class OpenUiDonutChartNode extends OpenUiNode {
  final String title;
  final List<Map<String, dynamic>>? slices;

  const OpenUiDonutChartNode({
    required super.id,
    required this.title,
    this.slices,
  });
}

class OpenUiEnvelopeGridNode extends OpenUiNode {
  final String title;
  final List<Map<String, dynamic>>? items;

  const OpenUiEnvelopeGridNode({
    required super.id,
    required this.title,
    this.items,
  });
}

class OpenUiInvestmentCardNode extends OpenUiNode {
  final String title;
  final String? total;
  final List<Map<String, dynamic>>? items;

  const OpenUiInvestmentCardNode({
    required super.id,
    required this.title,
    this.total,
    this.items,
  });
}

class OpenUiActionFormNode extends OpenUiNode {
  final String actionType; // 'add_transaction', 'self_transfer', 'update_budget', 'create_envelope', 'create_account', 'update_investment'
  final String title;
  final String summary;
  final double? amount;
  final String? payee;
  final String? accountName;
  final String? categoryName;
  final String? toAccountName;
  final bool isIncome;
  final Map<String, dynamic> rawArgs;
  OpenUiActionStatus status;

  OpenUiActionFormNode({
    required super.id,
    required this.actionType,
    required this.title,
    required this.summary,
    this.amount,
    this.payee,
    this.accountName,
    this.categoryName,
    this.toAccountName,
    this.isIncome = false,
    this.rawArgs = const {},
    this.status = OpenUiActionStatus.pending,
  });
}

class OpenUiSegment {
  final bool isOpenUi;
  final String? markdownText;
  final List<OpenUiNode> nodes;

  OpenUiSegment.markdown(String text)
      : isOpenUi = false,
        markdownText = text,
        nodes = const [];

  OpenUiSegment.openUi(this.nodes)
      : isOpenUi = true,
        markdownText = null;
}
