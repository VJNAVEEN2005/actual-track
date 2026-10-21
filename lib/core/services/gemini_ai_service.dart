import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../providers/app_provider.dart';
import '../openui/openui_models.dart';
import '../openui/openui_parser.dart';

class ToolExecutionResult {
  final String toolName;
  final String summary;
  final bool success;

  ToolExecutionResult({
    required this.toolName,
    required this.summary,
    required this.success,
  });
}

class ChatMessage {
  final String id;
  final String role; // 'user' | 'model' | 'system'
  final String text;
  final DateTime timestamp;
  final List<ToolExecutionResult> executedTools;
  final List<OpenUiSegment> segments;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.executedTools = const [],
    this.segments = const [],
  });
}

class GeminiAiService {
  static final GeminiAiService instance = GeminiAiService._init();
  GeminiAiService._init();

  static const List<Map<String, dynamic>> _toolDeclarations = [
    {
      'name': 'add_transaction',
      'description': 'Propose adding an expense or income transaction into the ledger.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'payee': {'type': 'STRING', 'description': 'Merchant, person, or description (e.g. Swiggy, Salary, Grocery)'},
          'amount': {'type': 'NUMBER', 'description': 'Amount in Indian Rupees (₹)'},
          'account_name': {'type': 'STRING', 'description': 'Account used (e.g. HDFC Checking, Cash Wallet, SBI Savings)'},
          'category_name': {'type': 'STRING', 'description': 'Budget envelope category (e.g. Groceries, Dining Out)'},
          'is_income': {'type': 'BOOLEAN', 'description': 'True for income/salary, False for expenses'},
          'notes': {'type': 'STRING', 'description': 'Optional transaction notes'},
        },
        'required': ['payee', 'amount', 'is_income'],
      },
    },
    {
      'name': 'self_transfer',
      'description': 'Propose transferring funds between two personal accounts.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'from_account': {'type': 'STRING', 'description': 'Source account to debit money from'},
          'to_account': {'type': 'STRING', 'description': 'Destination account to credit money to'},
          'amount': {'type': 'NUMBER', 'description': 'Amount to transfer in Indian Rupees (₹)'},
          'notes': {'type': 'STRING', 'description': 'Optional notes like SIP transfer, ATM cash withdrawal'},
        },
        'required': ['from_account', 'to_account', 'amount'],
      },
    },
    {
      'name': 'edit_transaction',
      'description': 'Propose modifying an existing transaction (amount, payee, account, or envelope).',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'search_query': {'type': 'STRING', 'description': 'Merchant/payee name to find the transaction (e.g. Swiggy, Coffee)'},
          'new_amount': {'type': 'NUMBER', 'description': 'Updated amount in ₹'},
          'new_payee': {'type': 'STRING', 'description': 'Updated payee name'},
          'new_category': {'type': 'STRING', 'description': 'Updated envelope category'},
          'new_account': {'type': 'STRING', 'description': 'Updated account name'},
          'notes': {'type': 'STRING', 'description': 'Updated notes'},
        },
        'required': ['search_query'],
      },
    },
    {
      'name': 'create_category_envelope',
      'description': 'Propose creating a new budget envelope category with an assigned monthly budget.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING', 'description': 'Category name (e.g. Gym & Fitness, Vacation Fund)'},
          'group_name': {'type': 'STRING', 'description': 'Group name: Essentials, Lifestyle, Savings & Goals, or Debt'},
          'budgeted_amount': {'type': 'NUMBER', 'description': 'Monthly budget allocation in ₹'},
        },
        'required': ['name', 'budgeted_amount'],
      },
    },
    {
      'name': 'update_envelope_budget',
      'description': 'Propose adjusting or reallocating the monthly budget amount for an envelope.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'category_name': {'type': 'STRING', 'description': 'Target envelope name'},
          'new_budget_amount': {'type': 'NUMBER', 'description': 'New monthly target amount in ₹'},
        },
        'required': ['category_name', 'new_budget_amount'],
      },
    },
    {
      'name': 'create_account',
      'description': 'Propose creating a new financial account (checking, savings, credit, cash, or investment).',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING', 'description': 'Account name (e.g. ICICI Bank, Zerodha Demat, Cash)'},
          'type': {'type': 'STRING', 'description': 'Account type: checking, savings, credit, cash, or investment'},
          'initial_balance': {'type': 'NUMBER', 'description': 'Starting balance in ₹'},
        },
        'required': ['name', 'type', 'initial_balance'],
      },
    },
    {
      'name': 'update_investment_portfolio',
      'description': 'Propose updating current valuation of an off-budget investment account (Stocks, Groww, Zerodha, Crypto).',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'account_name': {'type': 'STRING', 'description': 'Investment account name'},
          'new_market_value': {'type': 'NUMBER', 'description': 'Updated current valuation in ₹'},
          'notes': {'type': 'STRING', 'description': 'Optional reconciliation notes'},
        },
        'required': ['account_name', 'new_market_value'],
      },
    },
    {
      'name': 'schedule_recurring_bill',
      'description': 'Propose scheduling a recurring monthly bill or subscription.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'name': {'type': 'STRING', 'description': 'Bill or subscription name (e.g. Netflix, Wi-Fi, Rent)'},
          'amount': {'type': 'NUMBER', 'description': 'Amount in ₹'},
          'day_of_month': {'type': 'INTEGER', 'description': 'Day of month due (1-31)'},
          'account_name': {'type': 'STRING', 'description': 'Account to pay from'},
          'category_name': {'type': 'STRING', 'description': 'Envelope category'},
        },
        'required': ['name', 'amount', 'day_of_month'],
      },
    },
    {
      'name': 'get_financial_summary',
      'description': 'Retrieve real-time liquidity, inflow, outflow, and net worth overview.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {},
      },
    },
    {
      'name': 'get_spending_analysis',
      'description': 'Retrieve detailed category-by-category spending breakdown and envelope performance.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {},
      },
    },
    {
      'name': 'render_openui_dashboard',
      'description': 'Render an interactive In-Chat OpenUI dashboard widget directly in the conversation.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'dashboard_type': {
            'type': 'STRING',
            'description': 'Type: cashflow (Income vs Expense 30d graph), spending_donut (category breakdown), envelopes (budget meters), investments (portfolio vs cash), or health_score (savings rate gauge)',
          },
          'headline': {'type': 'STRING', 'description': 'Short headline for the widget'},
          'insight_summary': {'type': 'STRING', 'description': 'One sentence takeaway for the user'},
        },
        'required': ['dashboard_type'],
      },
    },
  ];

  Future<ChatMessage> sendMessage({
    required String prompt,
    required List<ChatMessage> history,
    required AppProvider provider,
  }) async {
    final apiKey = provider.geminiApiKey.trim();
    if (apiKey.isEmpty) {
      const errorText = '⚠️ **Gemini API Key Required**\n\nPlease add your free Google Gemini API key in **Settings** (accessible from the sidebar or top bar) to start chatting and generating live OpenUI financial widgets.';
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'model',
        text: errorText,
        timestamp: DateTime.now(),
        segments: OpenUiParser.parseMessage(errorText),
      );
    }

    final model = provider.geminiModel.trim().isNotEmpty ? provider.geminiModel : 'gemini-3.8-flash';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    // Build Financial Context
    final accountsSummary = provider.accounts.map((a) => '${a.name} (${a.type}): ₹${a.balance.toStringAsFixed(2)}').join(', ');
    final categoriesSummary = provider.categories.map((c) => '${c.name} (${c.groupName}): Budgeted ₹${c.budgeted.toStringAsFixed(2)}, Spent ₹${c.spent.toStringAsFixed(2)}, Left ₹${c.remaining.toStringAsFixed(2)}').join('; ');

    final systemPrompt = '''
You are Actual AI, an elite personal financial advisor and agent embedded in the Actual Track app.
Currency: Indian Rupees (₹).
Budgeting Methodology: Zero-Based Envelope Budgeting (Actual Budget style).

Current Financial State:
- Spendable Liquid Net Cash: ₹${provider.liquidNetWorth.toStringAsFixed(2)} (Checking, Savings, Cash Wallets, Credit)
- Off-Budget Investments: ₹${provider.totalInvestments.toStringAsFixed(2)} (Stocks, Groww, Zerodha, Crypto)
- Combined Net Worth: ₹${provider.totalNetWorth.toStringAsFixed(2)}
- Monthly Inflow: ₹${provider.monthlyInflow.toStringAsFixed(2)}
- Monthly Outflow: ₹${provider.monthlyOutflow.toStringAsFixed(2)}
- Available to Budget: ₹${provider.availableToBudget.toStringAsFixed(2)}
- Accounts: $accountsSummary
- Envelopes: $categoriesSummary

OpenUI (openui.com) Generative UI Protocol:
You can directly output OpenUI component blocks wrapped in ```openui ... ``` to render native interactive widgets in the user's chat!
Available OpenUI Components:
- `Metric(label: "...", value: "...", badge: "...", icon: "...")`
- `LineChart(title: "Cash Flow Trajectory (30 Days)", type: "cashflow")`
- `DonutChart(title: "Category Spending Breakdown")`
- `EnvelopeGrid(title: "Active Budget Envelopes")`
- `InvestmentCard(title: "Off-Budget Portfolio Assets")`
- `ActionForm(type: "add_transaction", title: "Add Expense", summary: "...", amount: 450.0, payee: "Swiggy", account: "Checking", category: "Dining Out")`
- `ActionForm(type: "self_transfer", title: "Transfer Funds", summary: "...", amount: 5000.0, account: "Checking", to_account: "Savings")`
- `ActionForm(type: "update_budget", title: "Update Budget", summary: "...", amount: 6000.0, category: "Groceries")`

RULES:
1. Liquid accounts (Checking, Savings, Cash) represent spendable cash.
2. Investment accounts (Zerodha, Groww, Stocks, Crypto) are tracking accounts; they contribute to Combined Net Worth but are kept SEPARATE from liquid spendable cash.
3. HUMAN-IN-THE-LOOP: When the user asks to add transactions, transfer funds, or change budgets: ALWAYS emit an `ActionForm(...)` or call the appropriate tool. A visual Action Preview Card will be shown to the user with [Confirm] & [Cancel] buttons. Tell the user you've prepared it for their confirmation. Never assume an action is confirmed before the user clicks Confirm.
4. When asked to show or analyze data, charts, or spending: emit `LineChart(...)`, `DonutChart(...)`, `EnvelopeGrid(...)`, or `InvestmentCard(...)` in an ```openui``` block or call "render_openui_dashboard".
5. ALWAYS format your responses with clean, rich Markdown:
   - Use bold for key figures and merchant names (e.g. **₹450.00**, **Swiggy**, **Main Checking**).
   - Use bullet points (`•` or `-`) for multiple details.
   - Use short, empowering sentences.
''';

    // Format conversation history
    final contents = <Map<String, dynamic>>[];
    for (final msg in history.take(10)) {
      contents.add({
        'role': msg.role == 'user' ? 'user' : 'model',
        'parts': [{'text': msg.text}],
      });
    }

    // Add current user prompt
    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    try {
      final requestBody = {
        'systemInstruction': {
          'parts': [{'text': systemPrompt}],
        },
        'contents': contents,
        'tools': [
          {'functionDeclarations': _toolDeclarations},
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 1024,
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        final errMsg = err['error']?['message'] ?? response.body;
        final errorText = '❌ **Gemini Error (${response.statusCode})**: $errMsg';
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: 'model',
          text: errorText,
          timestamp: DateTime.now(),
          segments: OpenUiParser.parseMessage(errorText),
        );
      }

      final resData = jsonDecode(response.body) as Map<String, dynamic>;
      final candidate = resData['candidates']?[0];
      final content = candidate?['content'];
      final parts = (content?['parts'] as List?) ?? [];

      final executedTools = <ToolExecutionResult>[];
      String modelReply = '';
      String openUiInjected = '';

      // Check for function calls
      final functionCallPart = parts.firstWhere(
        (p) => p.containsKey('functionCall'),
        orElse: () => null,
      );

      if (functionCallPart != null) {
        final fnCall = functionCallPart['functionCall'];
        final fnName = fnCall['name'] as String;
        final fnArgs = (fnCall['args'] as Map<String, dynamic>?) ?? {};

        // Convert function call to OpenUI Lang component
        openUiInjected = _functionCallToOpenUi(fnName, fnArgs, provider);

        // Execute function for summary
        final toolResult = _summarizeToolCall(fnName, fnArgs, provider);
        executedTools.add(toolResult);

        // Send function response back to Gemini for final conversational text
        final toolFollowupBody = {
          'systemInstruction': {
            'parts': [{'text': systemPrompt}],
          },
          'contents': [
            ...contents,
            {
              'role': 'model',
              'parts': [functionCallPart],
            },
            {
              'role': 'user',
              'parts': [
                {
                  'functionResponse': {
                    'name': fnName,
                    'response': {
                      'output': toolResult.summary,
                      'success': toolResult.success,
                    },
                  },
                },
              ],
            },
          ],
        };

        final followUpRes = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(toolFollowupBody),
        );

        if (followUpRes.statusCode == 200) {
          final followUpData = jsonDecode(followUpRes.body) as Map<String, dynamic>;
          final followUpParts = (followUpData['candidates']?[0]?['content']?['parts'] as List?) ?? [];
          for (final p in followUpParts) {
            if (p.containsKey('text')) {
              modelReply += p['text'] as String;
            }
          }
        } else {
          modelReply = toolResult.summary;
        }
      } else {
        // Plain text response
        for (final p in parts) {
          if (p.containsKey('text')) {
            modelReply += p['text'] as String;
          }
        }
      }

      // If OpenUI component was synthesized from tool call and not in text, append it
      if (openUiInjected.isNotEmpty && !modelReply.contains('```openui')) {
        modelReply = '$modelReply\n\n```openui\n$openUiInjected\n```';
      }

      // Auto-detect queries if neither tool nor openui block was returned
      if (!modelReply.contains('```openui')) {
        final lower = prompt.toLowerCase();
        if (lower.contains('graph') || lower.contains('cash flow') || lower.contains('trend')) {
          modelReply += '\n\n```openui\nchart = LineChart(title: "Cash Flow Trajectory (30 Days)", type: "cashflow")\n```';
        } else if (lower.contains('breakdown') || lower.contains('donut') || lower.contains('categories') || lower.contains('spending')) {
          modelReply += '\n\n```openui\ndonut = DonutChart(title: "Category Spending Breakdown")\n```';
        } else if (lower.contains('envelope') || lower.contains('budget status')) {
          modelReply += '\n\n```openui\nenvelopes = EnvelopeGrid(title: "Active Budget Envelopes")\n```';
        } else if (lower.contains('invest') || lower.contains('portfolio') || lower.contains('zerodha')) {
          modelReply += '\n\n```openui\ninvestments = InvestmentCard(title: "Off-Budget Portfolio Assets")\n```';
        }
      }

      final segments = OpenUiParser.parseMessage(modelReply);

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'model',
        text: modelReply,
        timestamp: DateTime.now(),
        executedTools: executedTools,
        segments: segments,
      );
    } catch (e) {
      final errorText = '❌ **Connection error**: $e';
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'model',
        text: errorText,
        timestamp: DateTime.now(),
        segments: OpenUiParser.parseMessage(errorText),
      );
    }
  }

  String _functionCallToOpenUi(String fnName, Map<String, dynamic> args, AppProvider provider) {
    switch (fnName) {
      case 'add_transaction':
        final payee = args['payee']?.toString() ?? 'Expense';
        final amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
        final isIncome = args['is_income'] == true;
        final acc = args['account_name']?.toString() ?? 'Main Checking';
        final cat = args['category_name']?.toString() ?? 'General';
        return 'action = ActionForm(type: "add_transaction", title: "${isIncome ? "Add Income" : "Add Expense"}", summary: "${isIncome ? "Income" : "Expense"}: ₹$amount for \\"$payee\\"", amount: $amount, payee: "$payee", account: "$acc", category: "$cat", is_income: $isIncome)';

      case 'self_transfer':
        final amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
        final fromAcc = args['from_account']?.toString() ?? 'Checking';
        final toAcc = args['to_account']?.toString() ?? 'Savings';
        return 'action = ActionForm(type: "self_transfer", title: "Transfer Funds", summary: "Transfer ₹$amount from \\"$fromAcc\\" to \\"$toAcc\\"", amount: $amount, account: "$fromAcc", to_account: "$toAcc")';

      case 'edit_transaction':
        final q = args['search_query']?.toString().toLowerCase() ?? '';
        final match = provider.transactions.where((t) => t.payee.toLowerCase().contains(q)).firstOrNull;
        final newAmt = (args['new_amount'] as num?)?.toDouble() ?? match?.amount ?? 0.0;
        final newPayee = args['new_payee']?.toString() ?? match?.payee ?? 'Transaction';
        final cat = args['new_category']?.toString() ?? (match?.categoryId != null ? provider.getCategoryById(match!.categoryId)?.name : null);
        final acc = args['new_account']?.toString() ?? (match != null ? provider.getAccountById(match.accountId)?.name : null);
        return 'action = ActionForm(type: "edit_transaction", title: "Edit Transaction", summary: "Update \\"$newPayee\\" to ₹$newAmt", amount: $newAmt, payee: "$newPayee", account: "${acc ?? ""}", category: "${cat ?? ""}", transaction_id: "${match?.id ?? ""}")';

      case 'create_category_envelope':
        final name = args['name']?.toString() ?? 'Envelope';
        final budget = (args['budgeted_amount'] as num?)?.toDouble() ?? 0.0;
        return 'action = ActionForm(type: "create_envelope", title: "Create Envelope", summary: "Create \\"$name\\" with ₹$budget budget", amount: $budget, category: "$name")';

      case 'update_envelope_budget':
        final cat = args['category_name']?.toString() ?? 'Envelope';
        final budget = (args['new_budget_amount'] as num?)?.toDouble() ?? 0.0;
        return 'action = ActionForm(type: "update_budget", title: "Update Budget", summary: "Update \\"$cat\\" budget to ₹$budget", amount: $budget, category: "$cat")';

      case 'render_openui_dashboard':
        final type = args['dashboard_type']?.toString().toLowerCase() ?? 'cashflow';
        if (type.contains('donut') || type.contains('spending')) {
          return 'donut = DonutChart(title: "Category Spending Breakdown")';
        } else if (type.contains('envelope')) {
          return 'envelopes = EnvelopeGrid(title: "Active Budget Envelopes")';
        } else if (type.contains('invest')) {
          return 'investments = InvestmentCard(title: "Off-Budget Portfolio Assets")';
        } else {
          return 'chart = LineChart(title: "Cash Flow Trajectory (30 Days)", type: "cashflow")';
        }

      default:
        return '';
    }
  }

  ToolExecutionResult _summarizeToolCall(String name, Map<String, dynamic> args, AppProvider provider) {
    switch (name) {
      case 'add_transaction':
        final payee = args['payee']?.toString() ?? 'Expense';
        final amount = args['amount'] ?? 0.0;
        final isIncome = args['is_income'] == true;
        return ToolExecutionResult(
          toolName: 'add_transaction',
          summary: 'Prepared ${isIncome ? "Income" : "Expense"} action for ₹$amount ("$payee"). Confirmation card shown to user.',
          success: true,
        );
      case 'self_transfer':
        final amount = args['amount'] ?? 0.0;
        return ToolExecutionResult(
          toolName: 'self_transfer',
          summary: 'Prepared Transfer action of ₹$amount. Confirmation card shown to user.',
          success: true,
        );
      case 'edit_transaction':
        final q = args['search_query'] ?? '';
        return ToolExecutionResult(
          toolName: 'edit_transaction',
          summary: 'Prepared modification for transaction matching "$q". Confirmation card shown to user.',
          success: true,
        );
      case 'render_openui_dashboard':
        final type = args['dashboard_type']?.toString() ?? 'cashflow';
        return ToolExecutionResult(
          toolName: 'render_openui_dashboard',
          summary: 'Rendered OpenUI component for $type.',
          success: true,
        );
      default:
        return ToolExecutionResult(
          toolName: name,
          summary: 'Action prepared for user confirmation.',
          success: true,
        );
    }
  }

  Future<bool> executeActionFormNode(OpenUiActionFormNode form, AppProvider provider) async {
    try {
      final args = form.rawArgs;
      switch (form.actionType) {
        case 'add_transaction':
          final payee = form.payee ?? args['payee']?.toString() ?? 'Quick Expense';
          final amount = form.amount ?? (args['amount'] as num?)?.toDouble() ?? 0.0;
          final isIncome = form.isIncome;
          final notes = args['notes']?.toString();

          String accountId = '';
          final accName = (form.accountName ?? args['account'] ?? args['account_name'])?.toString().toLowerCase();
          if (accName != null && accName.isNotEmpty) {
            final match = provider.accounts.where((a) => a.name.toLowerCase().contains(accName)).firstOrNull;
            if (match != null) accountId = match.id;
          }
          if (accountId.isEmpty) {
            if (provider.accounts.isEmpty) {
              await provider.addAccount(
                name: 'Main Checking',
                type: 'checking',
                balance: 0.0,
                colorValue: Colors.blue.toARGB32(),
                iconCode: Icons.account_balance.codePoint,
              );
            }
            accountId = provider.accounts.first.id;
          }

          String? categoryId;
          final catName = (form.categoryName ?? args['category'] ?? args['category_name'])?.toString().toLowerCase();
          if (catName != null && catName.isNotEmpty) {
            final match = provider.categories.where((c) => c.name.toLowerCase().contains(catName)).firstOrNull;
            categoryId = match?.id;
          }

          await provider.addTransaction(
            payee: payee,
            amount: amount,
            accountId: accountId,
            categoryId: categoryId,
            notes: notes ?? 'Logged via OpenUI AI',
            isIncome: isIncome,
          );
          form.status = OpenUiActionStatus.confirmed;
          return true;

        case 'self_transfer':
          final amount = form.amount ?? (args['amount'] as num?)?.toDouble() ?? 0.0;
          final fromStr = (form.accountName ?? args['from_account'])?.toString().toLowerCase() ?? '';
          final toStr = (form.toAccountName ?? args['to_account'])?.toString().toLowerCase() ?? '';

          final fromAcc = provider.accounts.where((a) => a.name.toLowerCase().contains(fromStr)).firstOrNull ??
              provider.accounts.first;
          final toAcc = provider.accounts.where((a) => a.name.toLowerCase().contains(toStr)).firstOrNull ??
              (provider.accounts.length > 1 ? provider.accounts[1] : provider.accounts.first);

          await provider.transferBetweenAccounts(
            fromAccountId: fromAcc.id,
            toAccountId: toAcc.id,
            amount: amount,
            notes: args['notes']?.toString() ?? 'Transferred via OpenUI AI',
          );
          form.status = OpenUiActionStatus.confirmed;
          return true;

        case 'create_envelope':
        case 'create_category_envelope':
          final nameStr = form.categoryName ?? args['name']?.toString() ?? 'New Envelope';
          final groupStr = args['group_name']?.toString() ?? 'Lifestyle';
          final budget = form.amount ?? (args['budgeted_amount'] as num?)?.toDouble() ?? 0.0;

          await provider.addCategory(
            name: nameStr,
            groupName: groupStr,
            budgeted: budget,
            colorValue: Colors.teal.toARGB32(),
            iconCode: Icons.all_inbox_outlined.codePoint,
          );
          form.status = OpenUiActionStatus.confirmed;
          return true;

        case 'update_budget':
        case 'update_envelope_budget':
          final catName = (form.categoryName ?? args['category_name'])?.toString().toLowerCase() ?? '';
          final newBudget = form.amount ?? (args['new_budget_amount'] as num?)?.toDouble() ?? 0.0;

          final match = provider.categories
              .where((c) => c.name.toLowerCase().contains(catName))
              .firstOrNull;

          if (match != null) {
            await provider.updateCategoryBudget(match.id, newBudget);
            form.status = OpenUiActionStatus.confirmed;
            return true;
          }
          return false;

        case 'create_account':
          final accName = form.accountName ?? args['name']?.toString() ?? 'Bank Account';
          final type = args['type']?.toString().toLowerCase() ?? 'checking';
          final bal = form.amount ?? (args['initial_balance'] as num?)?.toDouble() ?? 0.0;

          await provider.addAccount(
            name: accName,
            type: type,
            balance: bal,
            colorValue: type == 'investment' ? Colors.purple.toARGB32() : Colors.blue.toARGB32(),
            iconCode: type == 'investment' ? Icons.trending_up.codePoint : Icons.account_balance.codePoint,
          );
          form.status = OpenUiActionStatus.confirmed;
          return true;

        case 'update_investment_portfolio':
          final accName = (form.accountName ?? args['account_name'])?.toString().toLowerCase() ?? '';
          final newMarketVal = form.amount ?? (args['new_market_value'] as num?)?.toDouble() ?? 0.0;
          final notes = args['notes']?.toString();

          final match = provider.accounts
                  .where((a) => a.name.toLowerCase().contains(accName) && a.type == 'investment')
                  .firstOrNull ??
              provider.accounts.where((a) => a.type == 'investment').firstOrNull;

          if (match != null) {
            await provider.updateAccountBalance(match.id, newMarketVal, notes: notes);
            form.status = OpenUiActionStatus.confirmed;
            return true;
          }
          return false;

        case 'edit_transaction':
          final txId = args['transaction_id']?.toString() ?? '';
          final match = provider.transactions.where((t) => t.id == txId || (form.payee != null && t.payee.toLowerCase().contains(form.payee!.toLowerCase()))).firstOrNull;
          if (match != null) {
            final newAmount = form.amount ?? (args['new_amount'] as num?)?.toDouble() ?? match.amount;
            final newPayee = form.payee ?? args['new_payee']?.toString() ?? match.payee;
            String newAccountId = match.accountId;
            if (form.accountName != null && form.accountName!.isNotEmpty) {
              final acc = provider.accounts.where((a) => a.name.toLowerCase().contains(form.accountName!.toLowerCase())).firstOrNull;
              if (acc != null) newAccountId = acc.id;
            }
            String? newCategoryId = match.categoryId;
            if (form.categoryName != null && form.categoryName!.isNotEmpty) {
              final cat = provider.categories.where((c) => c.name.toLowerCase().contains(form.categoryName!.toLowerCase())).firstOrNull;
              if (cat != null) newCategoryId = cat.id;
            }

            await provider.updateTransaction(
              oldTx: match,
              payee: newPayee,
              amount: newAmount,
              accountId: newAccountId,
              categoryId: newCategoryId,
              notes: args['notes']?.toString() ?? match.notes,
              isIncome: match.isIncome,
              date: match.date,
            );
            form.status = OpenUiActionStatus.confirmed;
            return true;
          }
          return false;

        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }
}
