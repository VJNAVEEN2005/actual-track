import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/app_provider.dart';

class AddCategoryModal extends StatefulWidget {
  const AddCategoryModal({super.key});

  static Future<void> show(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: 480,
            child: AddCategoryModal(),
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
          child: const AddCategoryModal(),
        ),
      );
    }
  }

  @override
  State<AddCategoryModal> createState() => _AddCategoryModalState();
}

class _AddCategoryModalState extends State<AddCategoryModal> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  final _customGroupController = TextEditingController();

  String _selectedGroup = 'Essentials';
  bool _isCreatingCustomGroup = false;

  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;

  static const List<Color> _colors = [
    Color(0xFF2563EB), // Cobalt
    Color(0xFF059669), // Emerald
    Color(0xFF7C3AED), // Violet
    Color(0xFFF43F5E), // Coral
    Color(0xFFD97706), // Amber
    Color(0xFF0D9488), // Teal
    Color(0xFFE11D48), // Rose
    Color(0xFF4F46E5), // Indigo
    Color(0xFFEA580C), // Orange
    Color(0xFF0891B2), // Cyan
  ];

  static const List<IconData> _icons = [
    Icons.shopping_basket_outlined,
    Icons.restaurant_outlined,
    Icons.home_outlined,
    Icons.directions_car_outlined,
    Icons.devices_outlined,
    Icons.medical_services_outlined,
    Icons.flight_takeoff_outlined,
    Icons.fitness_center_outlined,
    Icons.school_outlined,
    Icons.pets_outlined,
    Icons.coffee_outlined,
    Icons.celebration_outlined,
    Icons.movie_outlined,
    Icons.wifi_outlined,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _customGroupController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
    final group = _isCreatingCustomGroup
        ? _customGroupController.text.trim()
        : _selectedGroup;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter category name')),
      );
      return;
    }

    if (group.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or specify a category group')),
      );
      return;
    }

    context.read<AppProvider>().addCategory(
          groupName: group,
          name: name,
          budgeted: budget,
          colorValue: _colors[_selectedColorIndex].toARGB32(),
          iconCode: _icons[_selectedIconIndex].codePoint,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final existingGroups = provider.categories
        .map((c) => c.groupName)
        .toSet()
        .toList();

    if (!existingGroups.contains('Essentials')) {
      existingGroups.insert(0, 'Essentials');
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Category Envelope', style: AppTypography.heading2),
                    Text(
                      'Assign a budget envelope to track expenditures',
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
            const SizedBox(height: 20),

            // Category Name
            TextField(
              controller: _nameController,
              style: AppTypography.body,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Electricity, Shopping, Child Care',
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Group Selection
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedGroup,
                    items: [
                      ...existingGroups.map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          )),
                      const DropdownMenuItem(
                        value: '__custom__',
                        child: Text('+ Custom Group...'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == '__custom__') {
                        setState(() => _isCreatingCustomGroup = true);
                      } else if (val != null) {
                        setState(() {
                          _selectedGroup = val;
                          _isCreatingCustomGroup = false;
                        });
                      }
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
                ),
              ],
            ),
            if (_isCreatingCustomGroup) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customGroupController,
                style: AppTypography.body,
                decoration: InputDecoration(
                  labelText: 'New Group Name',
                  hintText: 'e.g. Education, Taxes, Investments',
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Monthly Budget Allocation in Rupees
            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.currencyMedium,
              decoration: InputDecoration(
                labelText: 'Monthly Budget Allocation',
                prefixText: '₹ ',
                hintText: '0.00',
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Color Selector
            Text('Accent Color', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedColorIndex == index;
                  final color = _colors[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.textPrimary, width: 2.5)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Icon Selector
            Text('Category Icon', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.asMap().entries.map((entry) {
                final index = entry.key;
                final icon = entry.value;
                final isSelected = _selectedIconIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIconIndex = index),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _colors[_selectedColorIndex].withValues(alpha: 0.15)
                          : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: _colors[_selectedColorIndex], width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? _colors[_selectedColorIndex]
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
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
                  'Create Category Envelope',
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
