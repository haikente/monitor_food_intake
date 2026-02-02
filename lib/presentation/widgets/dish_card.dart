import 'package:flutter/material.dart';
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
        title: const Text('Sửa tên món ăn'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tên món ăn',
            hintText: 'Nhập tên món ăn',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _dish = _dish.copyWith(dishName: controller.text.trim());
                  widget.onDishChanged(_dish);
                });
                Navigator.pop(context);
              }
            },
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Tên món ăn
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dish.dishName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: _editDishName,
                    tooltip: 'Sửa tên món',
                  ),
                  if (widget.onRemove != null)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: widget.onRemove,
                      tooltip: 'Xóa món',
                      color: Colors.red,
                    ),
                ],
              ],
            ),
          ),

          // Tổng quan món ăn
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '${totalCalories.toStringAsFixed(0)} kcal',
                  color: Colors.orange,
                ),
                _buildSummaryItem(
                  icon: Icons.scale,
                  label: 'Khối lượng',
                  value: '${totalWeight.toStringAsFixed(0)}g',
                  color: Colors.blue,
                ),
                if (avgGI != null)
                  _buildSummaryItem(
                    icon: Icons.show_chart,
                    label: 'GI',
                    value: avgGI.toStringAsFixed(0),
                    color: _getGIColor(avgGI),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Danh sách thành phần
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Thành phần (${_dish.ingredients.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._dish.ingredients.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ingredient = entry.value;
                  return _buildIngredientItem(index, ingredient);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientItem(int index, FoodItem ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          // ignore: deprecated_member_use
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          radius: 16,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        title: Text(
          ingredient.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${ingredient.weight.toStringAsFixed(0)}g • ${ingredient.calories.toStringAsFixed(0)} kcal',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: widget.isEditing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editIngredient(index),
                    tooltip: 'Sửa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _removeIngredient(index),
                    tooltip: 'Xóa',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Color _getGIColor(double gi) {
    if (gi < 55) return Colors.green;
    if (gi < 70) return Colors.orange;
    return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa thành phần'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thành phần *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Khối lượng (g) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories (kcal) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proteinController,
              decoration: const InputDecoration(
                labelText: 'Protein (g/100g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _carbsController,
              decoration: const InputDecoration(
                labelText: 'Carbs (g/100g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatController,
              decoration: const InputDecoration(
                labelText: 'Fat (g/100g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _save,
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
