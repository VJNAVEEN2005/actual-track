import 'dart:convert';
import 'openui_models.dart';

class OpenUiParser {
  static final RegExp _openUiFenceRegex = RegExp(r'```(?:openui|OpenUI)([\s\S]*?)```', multiLine: true);

  /// Splits an incoming LLM message into sequential Markdown and OpenUI segments.
  static List<OpenUiSegment> parseMessage(String rawText) {
    final segments = <OpenUiSegment>[];
    if (rawText.trim().isEmpty) return segments;

    int lastIndex = 0;
    final matches = _openUiFenceRegex.allMatches(rawText);

    for (final match in matches) {
      if (match.start > lastIndex) {
        final textBefore = rawText.substring(lastIndex, match.start).trim();
        if (textBefore.isNotEmpty) {
          segments.add(OpenUiSegment.markdown(textBefore));
        }
      }

      final blockContent = match.group(1)?.trim() ?? '';
      if (blockContent.isNotEmpty) {
        final nodes = parseOpenUiBlock(blockContent);
        if (nodes.isNotEmpty) {
          segments.add(OpenUiSegment.openUi(nodes));
        }
      }

      lastIndex = match.end;
    }

    if (lastIndex < rawText.length) {
      final textAfter = rawText.substring(lastIndex).trim();
      if (textAfter.isNotEmpty) {
        segments.add(OpenUiSegment.markdown(textAfter));
      }
    }

    // If no ```openui fence was found, check if the raw text contains standalone OpenUI calls
    if (segments.isEmpty && rawText.isNotEmpty) {
      segments.add(OpenUiSegment.markdown(rawText));
    }

    return segments;
  }

  /// Parses lines inside an OpenUI code block.
  static List<OpenUiNode> parseOpenUiBlock(String blockContent) {
    final nodes = <OpenUiNode>[];
    final lines = blockContent.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('//') || line.startsWith('#')) continue;

      // Extract ComponentName and argument body
      // Matches: [identifier = ] ComponentName(arg1: val1, ...)
      final compMatch = RegExp(r'^(?:[a-zA-Z0-9_]+\s*=\s*)?([A-Z][a-zA-Z0-9_]*)\s*\(([\s\S]*)\)$').firstMatch(line);
      if (compMatch != null) {
        final compName = compMatch.group(1)!;
        final argsString = compMatch.group(2) ?? '';
        final args = _parseArguments(argsString);

        final id = 'node_${DateTime.now().millisecondsSinceEpoch}_$i';
        final node = _createNode(compName, id, args);
        if (node != null) {
          nodes.add(node);
        }
      }
    }

    return nodes;
  }

  static OpenUiNode? _createNode(String compName, String id, Map<String, dynamic> args) {
    switch (compName) {
      case 'Metric':
      case 'MetricCard':
      case 'KPI':
        return OpenUiMetricNode(
          id: id,
          label: args['label']?.toString() ?? args['title']?.toString() ?? 'Metric',
          value: args['value']?.toString() ?? '₹0.00',
          badge: args['badge']?.toString() ?? args['trend']?.toString(),
          icon: args['icon']?.toString(),
        );

      case 'LineChart':
      case 'CashFlowChart':
      case 'SplineChart':
        return OpenUiLineChartNode(
          id: id,
          title: args['title']?.toString() ?? 'Cash Flow Trajectory (30 Days)',
          type: args['type']?.toString() ?? 'cashflow',
        );

      case 'DonutChart':
      case 'SpendingDonut':
      case 'PieChart':
        return OpenUiDonutChartNode(
          id: id,
          title: args['title']?.toString() ?? 'Category Spending Breakdown',
        );

      case 'EnvelopeGrid':
      case 'Envelopes':
      case 'EnvelopeList':
        return OpenUiEnvelopeGridNode(
          id: id,
          title: args['title']?.toString() ?? 'Active Budget Envelopes',
        );

      case 'InvestmentCard':
      case 'Investments':
      case 'PortfolioCard':
        return OpenUiInvestmentCardNode(
          id: id,
          title: args['title']?.toString() ?? 'Off-Budget Portfolio Assets',
          total: args['total']?.toString(),
        );

      case 'ActionForm':
      case 'ActionProposal':
      case 'ConfirmAction':
        final actionType = args['type']?.toString() ?? args['action_type']?.toString() ?? 'add_transaction';
        final title = args['title']?.toString() ?? (actionType == 'add_transaction' ? 'Add Expense' : 'Confirm Action');
        final summary = args['summary']?.toString() ?? 'Please confirm action details';
        final amount = (args['amount'] as num?)?.toDouble();
        final payee = args['payee']?.toString();
        final accountName = args['account']?.toString() ?? args['account_name']?.toString();
        final categoryName = args['category']?.toString() ?? args['category_name']?.toString();
        final toAccountName = args['to_account']?.toString() ?? args['to_account_name']?.toString();
        final isIncome = args['is_income'] == true || args['income'] == true;

        return OpenUiActionFormNode(
          id: id,
          actionType: actionType,
          title: title,
          summary: summary,
          amount: amount,
          payee: payee,
          accountName: accountName,
          categoryName: categoryName,
          toAccountName: toAccountName,
          isIncome: isIncome,
          rawArgs: args,
        );

      default:
        return null;
    }
  }

  /// Parses key-value arguments inside ComponentName(key1: "val", key2: 123, ...)
  static Map<String, dynamic> _parseArguments(String argsString) {
    final result = <String, dynamic>{};
    if (argsString.trim().isEmpty) return result;

    // Pattern to match key: "value" or key: 123 or key: true or key: [...]
    final argRegex = RegExp(r'([a-zA-Z0-9_]+)\s*[:=]\s*("(?:\\.|[^"\\])*"|\[(?:\\.|[^\]\\])*\]|\{(?:\\.|[^\}\\])*\}|[^\s,]+)');
    for (final m in argRegex.allMatches(argsString)) {
      final key = m.group(1)!;
      final rawVal = m.group(2)!.trim();

      if (rawVal.startsWith('"') && rawVal.endsWith('"')) {
        result[key] = rawVal.substring(1, rawVal.length - 1).replaceAll(r'\"', '"');
      } else if (rawVal.startsWith('[') && rawVal.endsWith(']')) {
        try {
          result[key] = jsonDecode(rawVal);
        } catch (_) {
          result[key] = rawVal;
        }
      } else if (rawVal.startsWith('{') && rawVal.endsWith('}')) {
        try {
          result[key] = jsonDecode(rawVal);
        } catch (_) {
          result[key] = rawVal;
        }
      } else if (rawVal == 'true') {
        result[key] = true;
      } else if (rawVal == 'false') {
        result[key] = false;
      } else {
        final numVal = num.tryParse(rawVal);
        result[key] = numVal ?? rawVal;
      }
    }

    return result;
  }
}
