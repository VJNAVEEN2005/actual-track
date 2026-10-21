import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category_model.dart';
import '../../providers/app_provider.dart';

class EditBudgetDialog extends StatefulWidget {
  final CategoryModel category;

  const EditBudgetDialog({super.key, required this.category});

  static Future<void> show(BuildContext context, CategoryModel category) {
    return showDialog(
      context: context,
      builder: (context) => EditBudgetDialog(category: category),
    );
  }

  @override
  State<EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<EditBudgetDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late String _selectedGroup;
  late int _selectedColor;
  late int _selectedIcon;

  static const List<String> _groupOptions = [
    'Essentials',
    'Lifestyle',
    'Savings & Goals',
    'Debt & Bills',
    'Other',
  ];

  static const List<Color> _colorOptions = [
    Color(0xFF10B981), // Emerald
    Color(0xFF2563EB), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF43F5E), // Coral
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF64748B), // Slate
  ];

  static const List<IconData> _iconOptions = [
    Icons.home_outlined,
    Icons.restaurant_outlined,
    Icons.directions_car_outlined,
    Icons.shopping_bag_outlined,
    Icons.medical_services_outlined,
    Icons.devices_outlined,
    Icons.savings_outlined,
    Icons.movie_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _budgetController = TextEditingController(
      text: widget.category.budgeted.toStringAsFixed(2),
    );
    _selectedGroup = _groupOptions.contains(widget.category.groupName)
        ? widget.category.groupName
        : _groupOptions.first;
    _selectedColor = widget.category.colorValue;
    _selectedIcon = widget.category.iconCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_budgetController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter envelope name')),
      );
      return;
    }

    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }

    final updated = widget.category.copyWith(
      name: name,
      groupName: _selectedGroup,
      budgeted: amount,
      colorValue: _selectedColor,
      iconCode: _selectedIcon,
    );

    context.read<AppProvider>().updateCategory(updated);
    Navigator.of(context).pop();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete "${widget.category.name}" Envelope?'),
        content: const Text(
          'This envelope will be removed from your budget.\n\nAny past transactions assigned to this envelope will remain safely preserved in your ledger as "Uncategorized".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // close confirm dialog
              await context.read<AppProvider>().deleteCategory(widget.category.id);
              if (mounted) {
                Navigator.of(context).pop(); // close edit modal
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Envelope "${widget.category.name}" deleted.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Envelope'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppColors.hoverShadow,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(_selectedColor).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          IconData(_selectedIcon, fontFamily: 'MaterialIcons'),
                          color: Color(_selectedColor),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Envelope', style: AppTypography.heading2.copyWith(fontSize: 18)),
                          Text(
                            'Spent this month: ${Formatters.currency(widget.category.spent)}',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name Field
              TextField(
                controller: _nameController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  labelText: 'Envelope Name',
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Group Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGroup,
                items: _groupOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedGroup = val);
                },
                decoration: InputDecoration(
                  labelText: 'Category Group',
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Monthly Budget Allocation Field
              TextField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.currencyMedium,
                decoration: InputDecoration(
                  labelText: 'Monthly Budget Allocation',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Color Palette Picker
              Text('Envelope Color', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _colorOptions.map((color) {
                  final isSelected = _selectedColor == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color.toARGB32()),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Icon Selector
              Text('Envelope Icon', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _iconOptions.map((icon) {
                  final isSelected = _selectedIcon == icon.codePoint;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon.codePoint),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.surfaceSecondary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Color(_selectedColor), width: 1.5)
                            : Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected ? Color(_selectedColor) : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action Buttons: Delete on left, Cancel & Save on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.coral),
                    label: Text(
                      'Delete Envelope',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
