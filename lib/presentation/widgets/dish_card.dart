import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/dish.dart';
import '../../models/food_item.dart';

class DishCard extends StatefulWidget {
  final Dish dish;
  final bool isEditing;
  final Function(Dish) onDishChanged;
  final VoidCallback? onRemove;

  const DishCard({
    super.key,
    required this.dish,
    required this.isEditing,
    required this.onDishChanged,
    this.onRemove,
  });

  @override
  State<DishCard> createState() => _DishCardState();
}

class _DishCardState extends State<DishCard> {
  late Dish _dish;

  @override
  void initState() {
    super.initState();
    _dish = widget.dish;
  }

  @override
  void didUpdateWidget(DishCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dish != oldWidget.dish) {
      _dish = widget.dish;
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      final newIngredients = List<FoodItem>.from(_dish.ingredients);
      newIngredients.removeAt(index);
      _dish = _dish.copyWith(ingredients: newIngredients);
      widget.onDishChanged(_dish);
    });
  }

  void _editIngredient(int index) {
    final ingredient = _dish.ingredients[index];

    showDialog(
      context: context,
      builder: (context) => _EditIngredientDialog(
        ingredient: ingredient,
        onSave: (editedIngredient) {
          setState(() {
            final newIngredients = List<FoodItem>.from(_dish.ingredients);
            newIngredients[index] = editedIngredient;
            _dish = _dish.copyWith(ingredients: newIngredients);
            widget.onDishChanged(_dish);
          });
        },
      ),
    );
  }

  void _editDishName() {
    final controller = TextEditingController(text: _dish.dishName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sửa tên món ăn',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Tên món ăn',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintText: 'Nhập tên món ăn',
            prefixIcon: const Icon(Icons.restaurant_rounded,
                size: 20, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _dish = _dish.copyWith(dishName: controller.text.trim());
                  widget.onDishChanged(_dish);
                });
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _dish.totalCalories;
    final totalWeight = _dish.totalWeight;
    final avgGI = _dish.averageGI;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dish.dishName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (widget.isEditing) ...[
                  _buildIconAction(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    onTap: _editDishName,
                  ),
                  if (widget.onRemove != null) ...[
                    const SizedBox(width: 4),
                    _buildIconAction(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.dangerColor,
                      onTap: widget.onRemove!,
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Summary stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _buildSummaryItem(
                      icon: Icons.local_fire_department_rounded,
                      value: '${totalCalories.toStringAsFixed(0)} kcal',
                      color: AppColors.calorieColor,
                    ),
                    const VerticalDivider(
                        width: 1, thickness: 1, color: AppColors.divider),
                    _buildSummaryItem(
                      icon: Icons.monitor_weight_rounded,
                      value: '${totalWeight.toStringAsFixed(0)}g',
                      color: AppColors.weightColor,
                    ),
                    if (avgGI != null) ...[
                      const VerticalDivider(
                          width: 1, thickness: 1, color: AppColors.divider),
                      _buildSummaryItem(
                        icon: Icons.speed_rounded,
                        value: 'GI ${avgGI.toStringAsFixed(0)}',
                        color: _getGIColor(avgGI),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Ingredients header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.list_alt_rounded,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Thành phần (${_dish.ingredients.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Ingredients list
          ..._dish.ingredients.asMap().entries.map((entry) {
            return _buildIngredientItem(entry.key, entry.value);
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(int index, FoodItem ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ingredient.weight.toStringAsFixed(0)}g · ${ingredient.calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isEditing)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconAction(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    onTap: () => _editIngredient(index),
                    small: true,
                  ),
                  const SizedBox(width: 2),
                  _buildIconAction(
                    icon: Icons.close_rounded,
                    color: AppColors.dangerColor,
                    onTap: () => _removeIngredient(index),
                    small: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool small = false,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(small ? 6 : 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(small ? 6 : 8),
        child: Padding(
          padding: EdgeInsets.all(small ? 5 : 7),
          child: Icon(icon, size: small ? 14 : 17, color: color),
        ),
      ),
    );
  }

  Color _getGIColor(double gi) {
    if (gi < 55) return AppColors.primary;
    if (gi < 70) return AppColors.warningColor;
    return AppColors.dangerColor;
  }
}

/// Dialog để chỉnh sửa thành phần
class _EditIngredientDialog extends StatefulWidget {
  final FoodItem ingredient;
  final Function(FoodItem) onSave;

  const _EditIngredientDialog({
    required this.ingredient,
    required this.onSave,
  });

  @override
  State<_EditIngredientDialog> createState() => _EditIngredientDialogState();
}

class _EditIngredientDialogState extends State<_EditIngredientDialog> {
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient.name);
    _weightController =
        TextEditingController(text: widget.ingredient.weight.toString());
    _caloriesController =
        TextEditingController(text: widget.ingredient.calories.toString());
    _proteinController = TextEditingController(
        text: widget.ingredient.protein?.toString() ?? '');
    _carbsController =
        TextEditingController(text: widget.ingredient.carbs?.toString() ?? '');
    _fatController =
        TextEditingController(text: widget.ingredient.fat?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Chỉnh sửa thành phần',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(
              controller: _nameController,
              label: 'Tên thành phần *',
              icon: Icons.restaurant_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _weightController,
                    label: 'KL (g) *',
                    icon: Icons.monitor_weight_rounded,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildField(
                    controller: _caloriesController,
                    label: 'Calo *',
                    icon: Icons.local_fire_department_rounded,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _proteinController,
                    label: 'Protein',
                    icon: Icons.fitness_center_rounded,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildField(
                    controller: _carbsController,
                    label: 'Carbs',
                    icon: Icons.grain_rounded,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _fatController,
              label: 'Fat (g/100g)',
              icon: Icons.water_drop_rounded,
              isNumber: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  void _save() {
    try {
      final name = _nameController.text.trim();
      final weight = double.parse(_weightController.text.trim());
      final calories = double.parse(_caloriesController.text.trim());
      final protein = _proteinController.text.trim().isEmpty
          ? null
          : double.parse(_proteinController.text.trim());
      final carbs = _carbsController.text.trim().isEmpty
          ? null
          : double.parse(_carbsController.text.trim());
      final fat = _fatController.text.trim().isEmpty
          ? null
          : double.parse(_fatController.text.trim());

      if (name.isEmpty) {
        _showError('Vui lòng nhập tên thành phần');
        return;
      }

      final edited = widget.ingredient.copyWith(
        name: name,
        weight: weight,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );

      widget.onSave(edited);
      Navigator.pop(context);
    } catch (e) {
      _showError('Vui lòng nhập đúng định dạng số');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
