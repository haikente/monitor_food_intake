import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/food_analysis_entity.dart';
import '../../domain/entities/food_item_entity.dart';
import '../../domain/usecases/save_food_analysis.dart';
import '../../models/food_analysis.dart';
import '../../models/food_item.dart';
import '../../models/dish.dart';
import '../widgets/dish_card.dart';


class ResultScreen extends StatefulWidget {
  final FoodAnalysis analysis;

  const ResultScreen({
    super.key,
    required this.analysis,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late FoodAnalysis _analysis;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _analysis = widget.analysis;

    // Kiểm tra và tự động mở edit cho món Unknown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUnknownFoods();
    });
  }

  /// Kiểm tra món Unknown và prompt người dùng edit
  void _checkForUnknownFoods() {
    final unknownIndices = <int>[];
    for (int i = 0; i < _analysis.foods.length; i++) {
      final food = _analysis.foods[i];
      if (food.name.toLowerCase().contains('unknown') ||
          food.category == 'Chưa xác định') {
        unknownIndices.add(i);
      }
    }

    if (unknownIndices.isNotEmpty) {
      // Hiện dialog thông báo có món Unknown
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded,
              color: AppColors.warningColor, size: 48),
          title: const Text('Món ăn chưa xác định'),
          content: Text(
            'Phát hiện ${unknownIndices.length} món ăn không có trong database.\n\n'
            'Vui lòng chỉnh sửa để bổ sung thông tin dinh dưỡng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Bật chế độ edit và mở dialog cho món đầu tiên
                setState(() {
                  _isEditing = true;
                });
                Future.delayed(const Duration(milliseconds: 300), () {
                  _editFoodItem(unknownIndices.first);
                });
              },
              child: const Text('Sửa ngay'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ===== SLIVER APP BAR với ảnh =====
          SliverAppBar(
            expandedHeight: _analysis.imagePath != null ? 300 : 120,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEditing
                      ? AppColors.warningColor.withOpacity(0.9)
                      : Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                  tooltip: _isEditing ? 'Xong' : 'Chỉnh sửa',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Kết quả phân tích',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
              centerTitle: true,
              background: _analysis.imagePath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(_analysis.imagePath!),
                          fit: BoxFit.cover,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // ===== NỘI DUNG =====
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // ===== SUMMARY STATS =====
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryStatItem(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Calories',
                            value: _analysis.totalCalories.toStringAsFixed(0),
                            unit: 'kcal',
                            color: AppColors.calorieColor,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: AppColors.divider,
                        ),
                        Expanded(
                          child: _buildSummaryStatItem(
                            icon: Icons.monitor_weight_rounded,
                            label: 'Khối lượng',
                            value: _analysis.totalWeight.toStringAsFixed(0),
                            unit: 'g',
                            color: AppColors.weightColor,
                          ),
                        ),
                        if (_analysis.averageGI != null) ...[
                          Container(
                            width: 1,
                            height: 50,
                            color: AppColors.divider,
                          ),
                          Expanded(
                            child: _buildSummaryStatItem(
                              icon: Icons.speed_rounded,
                              label: 'Chỉ số GI',
                              value: _analysis.averageGI!.toStringAsFixed(0),
                              unit: _analysis.averageGI! < 55
                                  ? 'Thấp'
                                  : _analysis.averageGI! < 70
                                      ? 'TB'
                                      : 'Cao',
                              color: _getGIColor(_analysis.averageGI!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ===== DISHES SECTION =====
                if (_analysis.dishes != null &&
                    _analysis.dishes!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Món ăn (${_analysis.dishes!.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._analysis.dishes!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dish = entry.value;
                    return DishCard(
                      dish: dish,
                      isEditing: _isEditing,
                      onDishChanged: (updatedDish) {
                        setState(() {
                          final newDishes = List<Dish>.from(_analysis.dishes!);
                          newDishes[index] = updatedDish;
                          _analysis = FoodAnalysis(
                            foods: _analysis.foods,
                            dishes: newDishes,
                            timestamp: _analysis.timestamp,
                            imagePath: _analysis.imagePath,
                          );
                        });
                      },
                      onRemove: _isEditing
                          ? () {
                              setState(() {
                                final newDishes =
                                    List<Dish>.from(_analysis.dishes!);
                                newDishes.removeAt(index);
                                _analysis = FoodAnalysis(
                                  foods: _analysis.foods,
                                  dishes: newDishes.isEmpty ? null : newDishes,
                                  timestamp: _analysis.timestamp,
                                  imagePath: _analysis.imagePath,
                                );
                              });
                            }
                          : null,
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // ===== FOODS SECTION =====
                if (_analysis.foods.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.calorieColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.fastfood_rounded,
                            color: AppColors.calorieColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thực phẩm (${_analysis.foods.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_isEditing)
                          Material(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _addNewFoodItem,
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded,
                                        color: AppColors.primary, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      'Thêm',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ..._analysis.foods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final food = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFoodItemCard(food, index),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // ===== HEALTH ADVICE =====
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Lời khuyên sức khỏe',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _analysis.healthAdvice,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== SAVE BUTTON =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _saveAnalysis,
                        borderRadius: BorderRadius.circular(16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded,
                                color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Lưu kết quả',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Summary stat item cho top card
  Widget _buildSummaryStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// Widget cho food item card
  Widget _buildFoodItemCard(FoodItem food, int index) {
    final isUnknown = food.name.toLowerCase().contains('unknown') ||
        food.category == 'Chưa xác định';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isUnknown
            ? Border.all(color: AppColors.warningColor.withOpacity(0.5), width: 1.5)
            : Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: isUnknown
                ? AppColors.warningColor.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Unknown warning banner
          if (isUnknown)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warningColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chưa xác định - Vui lòng chỉnh sửa',
                      style: TextStyle(
                        color: AppColors.warningColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _editFoodItem(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warningColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Sửa',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: name + actions
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnknown
                              ? [AppColors.warningColor, AppColors.warningColor.withOpacity(0.8)]
                              : [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: isUnknown
                            ? const Icon(Icons.help_outline_rounded,
                                color: Colors.white, size: 20)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUnknown
                                  ? AppColors.warningColor
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (food.category != null &&
                              food.category != 'Chưa xác định')
                            Text(
                              food.category!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isEditing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIconAction(
                            icon: Icons.edit_rounded,
                            color: AppColors.primary,
                            onTap: () => _editFoodItem(index),
                          ),
                          const SizedBox(width: 4),
                          _buildIconAction(
                            icon: Icons.delete_rounded,
                            color: AppColors.dangerColor,
                            onTap: () => _deleteFoodItem(index),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Quick stats row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildQuickStat(
                        Icons.monitor_weight_rounded,
                        '${food.weight.toStringAsFixed(0)}g',
                        AppColors.weightColor,
                      ),
                      Container(width: 1, height: 24, color: AppColors.divider),
                      _buildQuickStat(
                        Icons.local_fire_department_rounded,
                        '${food.calories.toStringAsFixed(0)} kcal',
                        AppColors.calorieColor,
                      ),
                      if (food.glycemicIndex != null) ...[
                        Container(
                            width: 1, height: 24, color: AppColors.divider),
                        _buildQuickStat(
                          Icons.speed_rounded,
                          'GI ${food.glycemicIndex!.toStringAsFixed(0)}',
                          _getGIColor(food.glycemicIndex!),
                        ),
                      ],
                    ],
                  ),
                ),

                // Nutrition details
                if (food.protein != null ||
                    food.carbs != null ||
                    food.fat != null ||
                    food.fiber != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (food.protein != null)
                        _buildNutritionChip(
                          'P',
                          '${food.actualProtein!.toStringAsFixed(1)}g',
                          AppColors.proteinColor,
                        ),
                      if (food.carbs != null)
                        _buildNutritionChip(
                          'C',
                          '${food.actualCarbs!.toStringAsFixed(1)}g',
                          AppColors.carbsColor,
                        ),
                      if (food.fat != null)
                        _buildNutritionChip(
                          'F',
                          '${food.actualFat!.toStringAsFixed(1)}g',
                          AppColors.fatColor,
                        ),
                      if (food.fiber != null)
                        _buildNutritionChip(
                          'Fi',
                          '${food.actualFiber!.toStringAsFixed(1)}g',
                          AppColors.fiberColor,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
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

  Widget _buildNutritionChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Màu theo GI
  Color _getGIColor(double gi) {
    if (gi < 55) return AppColors.primary;
    if (gi < 70) return AppColors.warningColor;
    return AppColors.dangerColor;
  }

  /// Styled text field cho bottom sheet
  Widget _buildStyledTextField({
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _editFoodItem(int index) {
    final food = _analysis.foods[index];
    final nameController = TextEditingController(text: food.name);
    final weightController =
        TextEditingController(text: food.weight.toStringAsFixed(0));
    final caloriesController =
        TextEditingController(text: food.calories.toStringAsFixed(0));
    final giController = TextEditingController(
      text: food.glycemicIndex?.toStringAsFixed(0) ?? '',
    );

    bool isUpdatingCalories = false;

    void weightListener() {
      if (isUpdatingCalories) return;
      final weight = double.tryParse(weightController.text);
      if (weight != null && weight > 0) {
        isUpdatingCalories = true;
        final newCalories =
            (food.caloriesPer100g * weight / 100).toStringAsFixed(0);
        caloriesController.text = newCalories;
        isUpdatingCalories = false;
      }
    }

    weightController.addListener(weightListener);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Chỉnh sửa món ăn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStyledTextField(
                controller: nameController,
                label: 'Tên món ăn',
                icon: Icons.restaurant_rounded,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildStyledTextField(
                      controller: weightController,
                      label: 'Khối lượng (g)',
                      icon: Icons.monitor_weight_rounded,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStyledTextField(
                      controller: caloriesController,
                      label: 'Calories',
                      icon: Icons.local_fire_department_rounded,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildStyledTextField(
                controller: giController,
                label: 'Chỉ số GI (0-100) - Tùy chọn',
                icon: Icons.speed_rounded,
                isNumber: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      child: const Text('Hủy',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            try {
                              final newName = nameController.text.trim();
                              final newWeight =
                                  double.parse(weightController.text);
                              final newCalories =
                                  double.parse(caloriesController.text);
                              final newGI = giController.text.trim().isEmpty
                                  ? null
                                  : double.parse(giController.text);

                              if (newName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Tên món ăn không được để trống')),
                                );
                                return;
                              }
                              if (newWeight <= 0 || newCalories <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Khối lượng và calories phải > 0')),
                                );
                                return;
                              }
                              if (newGI != null && (newGI < 0 || newGI > 100)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Chỉ số GI phải từ 0-100')),
                                );
                                return;
                              }

                              final updatedFoods =
                                  List<FoodItem>.from(_analysis.foods);
                              updatedFoods[index] = FoodItem(
                                name: newName,
                                weight: newWeight,
                                calories: newCalories,
                                glycemicIndex: newGI,
                              );

                              setState(() {
                                _analysis = FoodAnalysis(
                                  foods: updatedFoods,
                                  dishes: _analysis.dishes,
                                  timestamp: _analysis.timestamp,
                                  imagePath: _analysis.imagePath,
                                );
                              });

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('✅ Đã cập nhật món ăn'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Lỗi: Vui lòng nhập số hợp lệ')),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Lưu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewFoodItem() {
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final caloriesController = TextEditingController();
    final giController = TextEditingController();

    double? caloriesPer100g;
    bool isUpdating = false;

    void updateCaloriesPer100g() {
      if (isUpdating) return;
      final weight = double.tryParse(weightController.text);
      final calories = double.tryParse(caloriesController.text);
      if (weight != null && weight > 0 && calories != null && calories > 0) {
        caloriesPer100g = calories * 100 / weight;
      }
    }

    void weightListener() {
      if (isUpdating) return;
      updateCaloriesPer100g();
      if (caloriesPer100g != null && caloriesPer100g! > 0) {
        final weight = double.tryParse(weightController.text);
        if (weight != null && weight > 0) {
          isUpdating = true;
          caloriesController.text =
              (caloriesPer100g! * weight / 100).toStringAsFixed(0);
          isUpdating = false;
        }
      }
    }

    void caloriesListener() {
      if (!isUpdating) updateCaloriesPer100g();
    }

    weightController.addListener(weightListener);
    caloriesController.addListener(caloriesListener);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Thêm món ăn mới',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStyledTextField(
                controller: nameController,
                label: 'Tên món ăn *',
                icon: Icons.restaurant_rounded,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildStyledTextField(
                      controller: weightController,
                      label: 'Khối lượng (g) *',
                      icon: Icons.monitor_weight_rounded,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStyledTextField(
                      controller: caloriesController,
                      label: 'Calories *',
                      icon: Icons.local_fire_department_rounded,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildStyledTextField(
                controller: giController,
                label: 'Chỉ số GI (0-100) - Tùy chọn',
                icon: Icons.speed_rounded,
                isNumber: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      child: const Text('Hủy',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            try {
                              final name = nameController.text.trim();
                              final weight =
                                  double.parse(weightController.text);
                              final calories =
                                  double.parse(caloriesController.text);
                              final gi = giController.text.trim().isEmpty
                                  ? null
                                  : double.parse(giController.text);

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Vui lòng nhập tên món ăn')),
                                );
                                return;
                              }
                              if (weight <= 0 || calories <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Khối lượng và calories phải > 0')),
                                );
                                return;
                              }
                              if (gi != null && (gi < 0 || gi > 100)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Chỉ số GI phải từ 0-100')),
                                );
                                return;
                              }

                              setState(() {
                                final updatedFoods =
                                    List<FoodItem>.from(_analysis.foods);
                                updatedFoods.add(FoodItem(
                                  name: name,
                                  weight: weight,
                                  calories: calories,
                                  glycemicIndex: gi,
                                ));
                                _analysis = FoodAnalysis(
                                  foods: updatedFoods,
                                  dishes: _analysis.dishes,
                                  timestamp: _analysis.timestamp,
                                  imagePath: _analysis.imagePath,
                                );
                              });

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('✅ Đã thêm món ăn mới'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Vui lòng nhập số hợp lệ')),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Thêm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteFoodItem(int index) {
    if (_analysis.foods.length <= 1 &&
        (_analysis.dishes == null || _analysis.dishes!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa! Phải có ít nhất 1 món ăn'),
          backgroundColor: AppColors.dangerColor,
        ),
      );
      return;
    }

    final food = _analysis.foods[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.delete_forever_rounded,
            color: AppColors.dangerColor, size: 48),
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa "${food.name}"?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final updatedFoods = List<FoodItem>.from(_analysis.foods);
                updatedFoods.removeAt(index);
                _analysis = FoodAnalysis(
                  foods: updatedFoods,
                  dishes: _analysis.dishes,
                  timestamp: _analysis.timestamp,
                  imagePath: _analysis.imagePath,
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ Đã xóa món ăn'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  /// Lưu kết quả
  Future<void> _saveAnalysis() async {
    try {
      final saveUseCase = getIt<SaveFoodAnalysisUseCase>();

      // Convert tất cả foods (từ foods list)
      final foodEntities = _analysis.foods.map((food) {
        return FoodItemEntity(
          name: food.name,
          nameEn: food.nameEn ?? '',
          weight: food.weight,
          calories: food.calories,
          protein:
              food.protein != null ? (food.protein! * food.weight / 100) : 0,
          carbs: food.carbs != null ? (food.carbs! * food.weight / 100) : 0,
          fat: food.fat != null ? (food.fat! * food.weight / 100) : 0,
          fiber: food.fiber != null ? (food.fiber! * food.weight / 100) : 0,
          glycemicIndex: food.glycemicIndex,
          category: food.category ?? 'undefined',
        );
      }).toList();

      // Convert dishes → flatten ingredients thành foods entities
      if (_analysis.dishes != null && _analysis.dishes!.isNotEmpty) {
        for (final dish in _analysis.dishes!) {
          for (final ingredient in dish.ingredients) {
            foodEntities.add(FoodItemEntity(
              name: '${dish.dishName} - ${ingredient.name}',
              nameEn: ingredient.nameEn ?? '',
              weight: ingredient.weight,
              calories: ingredient.calories,
              protein: ingredient.protein != null
                  ? (ingredient.protein! * ingredient.weight / 100)
                  : 0,
              carbs: ingredient.carbs != null
                  ? (ingredient.carbs! * ingredient.weight / 100)
                  : 0,
              fat: ingredient.fat != null
                  ? (ingredient.fat! * ingredient.weight / 100)
                  : 0,
              fiber: ingredient.fiber != null
                  ? (ingredient.fiber! * ingredient.weight / 100)
                  : 0,
              glycemicIndex: ingredient.glycemicIndex,
              category: ingredient.category ?? 'undefined',
            ));
          }
        }
      }

      // Kiểm tra có dữ liệu để lưu
      if (foodEntities.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có dữ liệu món ăn để lưu'),
              backgroundColor: AppColors.warningColor,
            ),
          );
        }
        return;
      }

      // Create entity
      final entity = FoodAnalysisEntity(
        id: const Uuid().v4(),
        foods: foodEntities,
        timestamp: DateTime.now(),
        imagePath: _analysis.imagePath,
        notes: null,
      );

      // Save to database
      await saveUseCase(entity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu kết quả phân tích!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );

        // Quay về màn hình chính sau 1 giây
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu dữ liệu: $e'),
            backgroundColor: AppColors.dangerColor,
          ),
        );
      }
    }
  }
}
