import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_provider.dart';

class AddScheduleModal extends StatefulWidget {
  const AddScheduleModal({super.key});

  static Future<void> show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: 480,
            child: AddScheduleModal(),
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
          child: const AddScheduleModal(),
        ),
      );
    }
  }

  @override
  State<AddScheduleModal> createState() => _AddScheduleModalState();
}

class _AddScheduleModalState extends State<AddScheduleModal> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedFrequency = 'monthly';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  bool _isIncome = false;

  String? _selectedAccountId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    if (provider.accounts.isNotEmpty) {
      _selectedAccountId = provider.accounts.first.id;
    }
    if (provider.categories.isNotEmpty) {
      _selectedCategoryId = provider.categories.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter schedule name')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select account')),
      );
      return;
    }

    context.read<AppProvider>().addSchedule(
          name: name,
          amount: amount,
          accountId: _selectedAccountId!,
          categoryId: _isIncome ? null : _selectedCategoryId,
          nextDate: _selectedDate,
          frequency: _selectedFrequency,
          isIncome: _isIncome,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Recurring Schedule', style: AppTypography.heading2),
                    Text(
                      'Calendar recurring bills, subscriptions or paydays',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Income / Expense Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isIncome ? AppColors.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_isIncome ? AppColors.softShadow : null,
                        ),
                        child: Center(
                          child: Text(
                            'Recurring Bill / Expense',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: !_isIncome ? AppColors.coral : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isIncome ? AppColors.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _isIncome ? AppColors.softShadow : null,
                        ),
                        child: Center(
                          child: Text(
                            'Recurring Income / Salary',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _isIncome ? AppColors.emerald : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Schedule Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Schedule Description',
                hintText: 'e.g. WiFi Bill, Netflix, House Rent, Salary',
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.currencyMedium,
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
            const SizedBox(height: 14),

            // Frequency Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedFrequency,
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'bi-weekly', child: Text('Bi-Weekly (Every 2 weeks)')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedFrequency = val);
              },
              decoration: InputDecoration(
                labelText: 'Frequency',
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Account
            DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              items: provider.accounts.map((acc) {
                return DropdownMenuItem(value: acc.id, child: Text(acc.name));
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
            if (!_isIncome) ...[
              const SizedBox(height: 14),
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
            const SizedBox(height: 14),

            // Due Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('First Due Date', style: AppTypography.caption),
                        const SizedBox(height: 2),
                        Text(Formatters.date(_selectedDate),
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.emerald),
                  ],
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
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save Schedule',
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
}
