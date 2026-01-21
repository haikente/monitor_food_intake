import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../domain/entities/food_analysis_entity.dart';
import '../../domain/usecases/delete_food_analysis.dart';
import '../../domain/usecases/get_food_analyses.dart';
import '../widgets/food_analysis_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _getUseCase = getIt<GetFoodAnalysesUseCase>();
  final _deleteUseCase = getIt<DeleteFoodAnalysisUseCase>();

  List<FoodAnalysisEntity> _analyses = [];
  bool _isLoading = true;
  String _filterPeriod = 'all'; // all, today, week, month

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() => _isLoading = true);

    try {
      List<FoodAnalysisEntity> analyses;

      switch (_filterPeriod) {
        case 'today':
          analyses = await _getUseCase.getTodayAnalyses();
          break;
        case 'week':
          analyses = await _getUseCase.getThisWeekAnalyses();
          break;
        case 'month':
          analyses = await _getUseCase.getThisMonthAnalyses();
          break;
        default:
          analyses = await _getUseCase();
      }

      setState(() {
        _analyses = analyses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  Future<void> _deleteAnalysis(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa phân tích này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _deleteUseCase(id);
        await _loadAnalyses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã xóa thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Lỗi xóa: $e')),
          );
        }
      }
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tất cả'),
            selected: _filterPeriod == 'all',
            onSelected: (_) {
              setState(() => _filterPeriod = 'all');
              _loadAnalyses();
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Hôm nay'),
            selected: _filterPeriod == 'today',
            onSelected: (_) {
              setState(() => _filterPeriod = 'today');
              _loadAnalyses();
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Tuần này'),
            selected: _filterPeriod == 'week',
            onSelected: (_) {
              setState(() => _filterPeriod = 'week');
              _loadAnalyses();
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Tháng này'),
            selected: _filterPeriod == 'month',
            onSelected: (_) {
              setState(() => _filterPeriod = 'month');
              _loadAnalyses();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    if (_analyses.isEmpty) return const SizedBox();

    final totalCalories = _analyses.fold<double>(
      0,
      (sum, analysis) => sum + analysis.totalCalories,
    );
    final avgCalories = totalCalories / _analyses.length;
    final avgGI = _analyses.fold<double>(
          0,
          (sum, analysis) => sum + (analysis.averageGI ?? 0),
        ) /
        _analyses.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
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
                icon: Icons.restaurant,
                label: 'Bữa ăn',
                value: '${_analyses.length}',
              ),
              _StatItem(
                icon: Icons.local_fire_department,
                label: 'TB Calo',
                value: avgCalories.toStringAsFixed(0),
              ),
              _StatItem(
                icon: Icons.speed,
                label: 'TB GI',
                value: avgGI.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử phân tích',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyses,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          if (!_isLoading) _buildStats(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _analyses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có lịch sử',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy chụp ảnh món ăn để bắt đầu!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAnalyses,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _analyses.length,
                          itemBuilder: (context, index) {
                            final analysis = _analyses[index];
                            return FoodAnalysisCard(
                              analysis: analysis,
                              onDelete: () => _deleteAnalysis(analysis.id),
                              onTap: () {
                                //
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
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
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
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
