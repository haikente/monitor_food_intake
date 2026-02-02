import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/injection.dart';
import '../../domain/entities/food_analysis_entity.dart';
import '../../domain/entities/food_item_entity.dart';
import '../../domain/usecases/save_food_analysis.dart';
import '../../models/food_analysis.dart';
import '../../models/food_item.dart';
import '../../models/dish.dart';
import '../widgets/dish_card.dart';

/// Màn hình hiển thị kết quả phân tích
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
              color: Colors.orange, size: 48),
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
      appBar: AppBar(
        title: Text('Kết quả phân tích', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.black,),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            tooltip: _isEditing ? 'Xong' : 'Chỉnh sửa',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bữa ăn
            if (_analysis.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: Image.file(
                    File(_analysis.imagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Summary cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (_analysis.dishes != null &&
                      _analysis.dishes!.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Danh sách món ăn (${_analysis.dishes!.length} món)',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dishes list
                    ..._analysis.dishes!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dish = entry.value;
                      return DishCard(
                        dish: dish,
                        isEditing: _isEditing,
                        onDishChanged: (updatedDish) {
                          setState(() {
                            final newDishes =
                                List<Dish>.from(_analysis.dishes!);
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
                                    dishes:
                                        newDishes.isEmpty ? null : newDishes,
                                    timestamp: _analysis.timestamp,
                                    imagePath: _analysis.imagePath,
                                  );
                                });
                              }
                            : null,
                      );
                    }),

                    const SizedBox(height: 24),
                  ],

                  // Danh sách thực phẩm (foods - legacy format)
                  if (_analysis.foods.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thực phẩm riêng lẻ (${_analysis.foods.length})',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: Colors.green,
                            iconSize: 32,
                            onPressed: _addNewFoodItem,
                            tooltip: 'Thêm món',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Food items list
                    ..._analysis.foods.asMap().entries.map((entry) {
                      final index = entry.key;
                      final food = entry.value;
                      return _buildFoodItemCard(food, index);
                    }),

                    const SizedBox(height: 24),
                  ],

                  // Lời khuyên sức khỏe
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.health_and_safety,
                                color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Lời khuyên sức khỏe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _analysis.healthAdvice,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.green[900],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nút lưu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveAnalysis,
                      icon: Icon(Icons.save_outlined),
                      label: const Text(
                        'Lưu kết quả',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Widget cho food item card
  Widget _buildFoodItemCard(FoodItem food, int index) {
    // Kiểm tra xem món ăn có phải "Unknown" không
    final isUnknown = food.name.toLowerCase().contains('unknown') ||
        food.category == 'Chưa xác định';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnknown
            ? BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      color: isUnknown ? Colors.orange[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cảnh báo cho món Unknown
            if (isUnknown) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange[800], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Món ăn không xác định - Vui lòng chỉnh sửa thông tin',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _editFoodItem(index),
                      child: const Text('Sửa ngay'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Tên món ăn
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isUnknown
                        ? Colors.orange
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isUnknown
                        ? const Icon(Icons.help_outline,
                            color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    food.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnknown ? Colors.orange[800] : null,
                    ),
                  ),
                ),
                if (_isEditing)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editFoodItem(index),
                        color: Colors.blue,
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteFoodItem(index),
                        color: Colors.red,
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Thông tin chi tiết
            _buildInfoRow(
              Icons.monitor_weight,
              'Khối lượng',
              '${food.weight.toStringAsFixed(0)}g',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.local_fire_department,
              'Calories',
              '${food.calories.toStringAsFixed(0)} kcal',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.info_outline,
              'Calories/100g',
              '${food.caloriesPer100g.toStringAsFixed(0)} kcal',
            ),
            if (food.glycemicIndex != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.analytics,
                'Chỉ số GI',
                '${food.glycemicIndex!.toStringAsFixed(0)} (${food.giLevel})',
                color: _getGIColor(food.glycemicIndex!),
              ),
            ],
            // Thông tin dinh dưỡng chi tiết
            if (food.protein != null ||
                food.carbs != null ||
                food.fat != null ||
                food.fiber != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (food.protein != null) ...[
                _buildInfoRow(
                  Icons.fitness_center,
                  'Protein',
                  '${food.actualProtein!.toStringAsFixed(1)}g (${food.protein!.toStringAsFixed(1)}g/100g)',
                ),
                const SizedBox(height: 8),
              ],
              if (food.carbs != null) ...[
                _buildInfoRow(
                  Icons.rice_bowl,
                  'Carbs',
                  '${food.actualCarbs!.toStringAsFixed(1)}g (${food.carbs!.toStringAsFixed(1)}g/100g)',
                ),
                const SizedBox(height: 8),
              ],
              if (food.fat != null) ...[
                _buildInfoRow(
                  Icons.water_drop,
                  'Fat',
                  '${food.actualFat!.toStringAsFixed(1)}g (${food.fat!.toStringAsFixed(1)}g/100g)',
                ),
                const SizedBox(height: 8),
              ],
              if (food.fiber != null) ...[
                _buildInfoRow(
                  Icons.grass,
                  'Fiber',
                  '${food.actualFiber!.toStringAsFixed(1)}g (${food.fiber!.toStringAsFixed(1)}g/100g)',
                ),
              ],
              if (food.category != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.category,
                  'Phân loại',
                  food.category!,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Widget cho info row
  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// Màu theo GI
  Color _getGIColor(double gi) {
    if (gi < 55) return Colors.green;
    if (gi < 70) return Colors.orange;
    return Colors.red;
  }

  void _editFoodItem(int index) {
    final food = _analysis.foods[index];

    // Controllers
    final nameController = TextEditingController(text: food.name);
    final weightController =
        TextEditingController(text: food.weight.toStringAsFixed(0));
    final caloriesController =
        TextEditingController(text: food.calories.toStringAsFixed(0));
    final giController = TextEditingController(
      text: food.glycemicIndex?.toStringAsFixed(0) ?? '',
    );

    // Flag to prevent infinite loops
    bool isUpdatingCalories = false;

    // Auto-calculate calories when weight changes
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Chỉnh sửa món ăn',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên món ăn',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Khối lượng (g)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_fire_department),
                  helperText: 'Tự động tính khi thay đổi khối lượng',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: giController,
                decoration: const InputDecoration(
                  labelText: 'Chỉ số GI (0-100)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.analytics),
                  hintText: 'Để trống nếu không biết',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Validate and save
              try {
                final newName = nameController.text.trim();
                final newWeight = double.parse(weightController.text);
                final newCalories = double.parse(caloriesController.text);
                final newGI = giController.text.trim().isEmpty
                    ? null
                    : double.parse(giController.text);

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tên món ăn không được để trống')),
                  );
                  return;
                }

                if (newWeight <= 0 || newCalories <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Khối lượng và calories phải > 0')),
                  );
                  return;
                }

                if (newGI != null && (newGI < 0 || newGI > 100)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chỉ số GI phải từ 0-100')),
                  );
                  return;
                }

                // Update food item
                final updatedFoods = List<FoodItem>.from(_analysis.foods);
                updatedFoods[index] = FoodItem(
                  name: newName,
                  weight: newWeight,
                  calories: newCalories,
                  glycemicIndex: newGI,
                );

                // Update analysis
                setState(() {
                  _analysis = FoodAnalysis(
                    foods: updatedFoods,
                    timestamp: _analysis.timestamp,
                    imagePath: _analysis.imagePath,
                  );
                });

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật món ăn'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: Vui lòng nhập số hợp lệ')),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Lưu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _addNewFoodItem() {
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final caloriesController = TextEditingController();
    final giController = TextEditingController();

    // Store calories per 100g for auto-calculation
    double? caloriesPer100g;
    bool isUpdating = false;

    // Calculate caloriesPer100g when both weight and calories are entered
    void updateCaloriesPer100g() {
      if (isUpdating) return;
      final weight = double.tryParse(weightController.text);
      final calories = double.tryParse(caloriesController.text);
      if (weight != null && weight > 0 && calories != null && calories > 0) {
        caloriesPer100g = calories * 100 / weight;
      }
    }

    // When weight changes, recalculate calories if caloriesPer100g is known
    void weightListener() {
      if (isUpdating) return;
      updateCaloriesPer100g();
      if (caloriesPer100g != null && caloriesPer100g! > 0) {
        final weight = double.tryParse(weightController.text);
        if (weight != null && weight > 0) {
          isUpdating = true;
          final newCalories =
              (caloriesPer100g! * weight / 100).toStringAsFixed(0);
          caloriesController.text = newCalories;
          isUpdating = false;
        }
      }
    }

    void caloriesListener() {
      if (!isUpdating) {
        updateCaloriesPer100g();
      }
    }

    weightController.addListener(weightListener);
    caloriesController.addListener(caloriesListener);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Thêm món ăn mới',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên món ăn *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Khối lượng (g) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monitor_weight),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: giController,
                decoration: const InputDecoration(
                  labelText: 'Chỉ số GI (0-100)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.analytics),
                  hintText: 'Tùy chọn',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              try {
                final name = nameController.text.trim();
                final weight = double.parse(weightController.text);
                final calories = double.parse(caloriesController.text);
                final gi = giController.text.trim().isEmpty
                    ? null
                    : double.parse(giController.text);

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên món ăn')),
                  );
                  return;
                }

                if (weight <= 0 || calories <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Khối lượng và calories phải > 0')),
                  );
                  return;
                }

                if (gi != null && (gi < 0 || gi > 100)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chỉ số GI phải từ 0-100')),
                  );
                  return;
                }

                // Add new food
                setState(() {
                  final updatedFoods = List<FoodItem>.from(_analysis.foods);
                  updatedFoods.add(FoodItem(
                    name: name,
                    weight: weight,
                    calories: calories,
                    glycemicIndex: gi,
                  ));
                  _analysis = FoodAnalysis(
                    foods: updatedFoods,
                    timestamp: _analysis.timestamp,
                    imagePath: _analysis.imagePath,
                  );
                });

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thêm món ăn mới'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập số hợp lệ')),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteFoodItem(int index) {
    if (_analysis.foods.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa! Phải có ít nhất 1 món ăn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final food = _analysis.foods[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa "${food.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final updatedFoods = List<FoodItem>.from(_analysis.foods);
                updatedFoods.removeAt(index);
                _analysis = FoodAnalysis(
                  foods: updatedFoods,
                  timestamp: _analysis.timestamp,
                  imagePath: _analysis.imagePath,
                );
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa món ăn'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
      // Convert old model to new entity
      final saveUseCase = getIt<SaveFoodAnalysisUseCase>();

      // Convert foods (old FoodItem doesn't have all fields, use defaults)
      final foods = _analysis.foods.map((food) {
        return FoodItemEntity(
          name: food.name,
          nameEn: '', // Old model doesn't have this
          weight: food.weight,
          calories: food.calories,
          protein: 0, // Old model doesn't have this, default to 0
          carbs: 0, // Old model doesn't have this
          fat: 0, // Old model doesn't have this
          fiber: 0, // Old model doesn't have this
          glycemicIndex: food.glycemicIndex,
          category: 'undefined', // Old model doesn't have this
        );
      }).toList();

      // Create entity
      final entity = FoodAnalysisEntity(
        id: const Uuid().v4(),
        foods: foods,
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
