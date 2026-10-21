import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/app_provider.dart';
import '../../providers/navigation_provider.dart';

enum TransactionFormType { expense, income, transfer }

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  static Future<void> show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: 500,
            child: AddTransactionModal(),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const AddTransactionModal(),
        ),
      );
    }
  }

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  TransactionFormType _formType = TransactionFormType.expense;
  final _payeeController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _selectedDate = DateTime.now();

  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    if (provider.accounts.isNotEmpty) {
      _selectedAccountId = provider.accounts.first.id;
      if (provider.accounts.length > 1) {
        _selectedToAccountId = provider.accounts[1].id;
      }
    }
    if (provider.categories.isNotEmpty) {
      _selectedCategoryId = provider.categories.first.id;
    }
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    if (_formType == TransactionFormType.transfer) {
      if (_selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination account')),
        );
        return;
      }

      if (_selectedAccountId == _selectedToAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts must be different')),
        );
        return;
      }

      provider.transferBetweenAccounts(
        fromAccountId: _selectedAccountId!,
        toAccountId: _selectedToAccountId!,
        amount: amount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        date: _selectedDate,
      );

      Navigator.of(context).pop();
      return;
    }

    // Expense or Income
    final payee = _payeeController.text.trim();
    if (payee.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter payee / description')),
      );
      return;
    }

    provider.addTransaction(
      payee: payee,
      amount: amount,
      accountId: _selectedAccountId!,
      categoryId: _formType == TransactionFormType.income ? null : _selectedCategoryId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isIncome: _formType == TransactionFormType.income,
      date: _selectedDate,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTransfer = _formType == TransactionFormType.transfer;
    final isIncome = _formType == TransactionFormType.income;

    if (provider.accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppColors.hoverShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, size: 36, color: AppColors.emerald),
            ),
            const SizedBox(height: 16),
            Text('No Accounts Found', style: AppTypography.heading2),
            const SizedBox(height: 8),
            Text(
              'Before adding a transaction, please create at least one account (e.g. Bank Account, Savings, or Cash Wallet).',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<NavigationProvider>().setIndex(3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.hoverShadow,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTransfer ? 'Self Account Transfer' : 'Add Transaction',
                  style: AppTypography.heading2,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3-Way Form Type Toggle: Expense / Income / Self Transfer
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _toggleOption(
                    title: 'Expense',
                    type: TransactionFormType.expense,
                    activeColor: AppColors.coral,
                  ),
                  _toggleOption(
                    title: 'Income',
                    type: TransactionFormType.income,
                    activeColor: AppColors.emerald,
                  ),
                  _toggleOption(
                    title: 'Self Transfer',
                    type: TransactionFormType.transfer,
                    activeColor: AppColors.cobalt,
                    icon: Icons.swap_horiz_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.currencyMedium,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // If Transfer, show Source and Destination Dropdowns
            if (isTransfer) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                items: provider.accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('From: ${acc.name} (${acc.type.toUpperCase()})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                decoration: InputDecoration(
                  labelText: 'Source Account (Debit)',
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedToAccountId,
                items: provider.accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('To: ${acc.name} (${acc.type.toUpperCase()})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedToAccountId = val),
                decoration: InputDecoration(
                  labelText: 'Destination Account (Credit)',
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ] else ...[
              // Payee Field for standard expense/income
              TextField(
                controller: _payeeController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  labelText: 'Payee / Description',
                  hintText: isIncome ? 'e.g. Salary, Dividend, Freelance' : 'e.g. Whole Foods, Swiggy, Uber',
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Account Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                items: provider.accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text(acc.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                decoration: InputDecoration(
                  labelText: 'Account',
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (!isIncome) ...[
                const SizedBox(height: 16),
                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  items: provider.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text('${cat.groupName} • ${cat.name}'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  decoration: InputDecoration(
                    labelText: 'Category Envelope',
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),
            // Notes
            TextField(
              controller: _notesController,
              style: AppTypography.body,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: isTransfer ? 'e.g. Monthly SIP investment, ATM Cash' : 'Add context or tags',
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTransfer
                      ? AppColors.cobalt
                      : (isIncome ? AppColors.emerald : AppColors.coral),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isTransfer
                      ? 'Execute Transfer'
                      : (isIncome ? 'Save Income' : 'Save Expense'),
                  style: AppTypography.heading3.copyWith(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleOption({
    required String title,
    required TransactionFormType type,
    required Color activeColor,
    IconData? icon,
  }) {
    final isSelected = _formType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _formType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? AppColors.softShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isSelected ? activeColor : AppColors.textSecondary),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isSelected ? activeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
