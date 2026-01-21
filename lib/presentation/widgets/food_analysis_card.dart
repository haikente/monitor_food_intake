import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/food_analysis_entity.dart';

class FoodAnalysisCard extends StatelessWidget {
  final FoodAnalysisEntity analysis;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const FoodAnalysisCard({
    super.key,
    required this.analysis,
    this.onDelete,
    this.onTap,
  });

  Color _getCalorieColor(double calories) {
    if (calories < 300) return Colors.green;
    if (calories < 600) return Colors.orange;
    return Colors.red;
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Time + Delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(analysis.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade300,
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Food items
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: analysis.foods.take(3).map((food) {
                  return Chip(
                    label: Text(
                      food.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.restaurant, size: 16),
                    backgroundColor: Colors.green.shade50,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              if (analysis.foodCount > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${analysis.foodCount - 3} món khác',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  // Calories
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getCalorieColor(analysis.totalCalories)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getCalorieColor(analysis.totalCalories)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 20,
                            color: _getCalorieColor(analysis.totalCalories),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${analysis.totalCalories.toStringAsFixed(0)} kcal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _getCalorieColor(analysis.totalCalories),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // GI
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getGIColor(analysis.averageGI).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _getGIColor(analysis.averageGI).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.speed,
                            size: 20,
                            color: _getGIColor(analysis.averageGI),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            analysis.averageGI != null
                                ? 'GI ${analysis.averageGI!.toStringAsFixed(0)}'
                                : 'N/A',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _getGIColor(analysis.averageGI),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Weight
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.monitor_weight_outlined,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${analysis.totalWeight.toStringAsFixed(0)}g',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Notes (if any)
              if (analysis.notes != null && analysis.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          analysis.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
