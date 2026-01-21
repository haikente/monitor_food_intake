import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/food_analysis_entity.dart';
import '../bloc/food_analysis_bloc.dart';
import '../bloc/food_analysis_event.dart';

class FoodAnalysisDetailScreen extends StatefulWidget {
  final FoodAnalysisEntity analysis;

  const FoodAnalysisDetailScreen({
    super.key,
    required this.analysis,
  });

  @override
  State<FoodAnalysisDetailScreen> createState() =>
      _FoodAnalysisDetailScreenState();
}

class _FoodAnalysisDetailScreenState extends State<FoodAnalysisDetailScreen> {
  late TextEditingController _notesController;
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.analysis.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _getGIColor(double? gi) {
    if (gi == null) return Colors.grey;
    if (gi < 55) return Colors.green;
    if (gi < 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết phân tích'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditingNotes)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNotes,
              tooltip: 'Lưu',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(widget.analysis.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: widget.analysis.totalCalories.toStringAsFixed(0),
                      ),
                      _StatItem(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Khối lượng',
                        value:
                            '${widget.analysis.totalWeight.toStringAsFixed(0)}g',
                      ),
                      if (widget.analysis.averageGI != null)
                        _StatItem(
                          icon: Icons.speed,
                          label: 'TB GI',
                          value: widget.analysis.averageGI!.toStringAsFixed(0),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Food List
            Text(
              'Danh sách món ăn (${widget.analysis.foodCount})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...widget.analysis.foods.asMap().entries.map((entry) {
              final index = entry.key;
              final food = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              food.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              label: 'Khối lượng',
                              value: '${food.weight.toStringAsFixed(0)}g',
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              label: 'Calories',
                              value: '${food.calories.toStringAsFixed(0)} kcal',
                            ),
                          ),
                        ],
                      ),
                      if (food.protein != null ||
                          food.carbs != null ||
                          food.fat != null ||
                          food.fiber != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (food.protein != null)
                              Expanded(
                                child: _InfoItem(
                                  label: 'Protein',
                                  value: '${food.protein!.toStringAsFixed(1)}g',
                                ),
                              ),
                            if (food.carbs != null)
                              Expanded(
                                child: _InfoItem(
                                  label: 'Carbs',
                                  value: '${food.carbs!.toStringAsFixed(1)}g',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (food.fat != null)
                              Expanded(
                                child: _InfoItem(
                                  label: 'Fat',
                                  value: '${food.fat!.toStringAsFixed(1)}g',
                                ),
                              ),
                            if (food.fiber != null)
                              Expanded(
                                child: _InfoItem(
                                  label: 'Fiber',
                                  value: '${food.fiber!.toStringAsFixed(1)}g',
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (food.glycemicIndex != null) ...[
                        const SizedBox(height: 8),
                        _InfoItem(
                          label: 'Chỉ số GI',
                          value:
                              '${food.glycemicIndex!.toStringAsFixed(0)} (${food.giLevel})',
                          color: _getGIColor(food.glycemicIndex),
                        ),
                      ],
                      if (food.category != null) ...[
                        const SizedBox(height: 8),
                        _InfoItem(
                          label: 'Phân loại',
                          value: food.category!,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Notes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isEditingNotes ? Icons.close : Icons.edit,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditingNotes = !_isEditingNotes;
                      if (!_isEditingNotes) {
                        // Reset text khi cancel
                        _notesController.text = widget.analysis.notes ?? '';
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isEditingNotes)
              TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Nhập ghi chú...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.analysis.notes?.isEmpty ?? true
                      ? 'Chưa có ghi chú'
                      : widget.analysis.notes!,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.analysis.notes?.isEmpty ?? true
                        ? Colors.grey.shade500
                        : Colors.black87,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Health Advice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety,
                          color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Lời khuyên sức khỏe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.analysis.healthAdvice,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blue.shade900,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNotes() {
    final newNotes = _notesController.text.trim();

    // Update via BLoC
    context.read<FoodAnalysisBloc>().add(
          UpdateAnalysisNotes(
            id: widget.analysis.id,
            notes: newNotes,
          ),
        );

    setState(() {
      _isEditingNotes = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang lưu ghi chú...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Pop back after save
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
