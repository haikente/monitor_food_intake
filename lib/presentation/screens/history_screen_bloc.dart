import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';
import '../bloc/food_analysis_bloc.dart';
import '../bloc/food_analysis_event.dart';
import '../bloc/food_analysis_state.dart';
import '../widgets/food_analysis_card.dart';
import 'food_analysis_detail_screen.dart';

class HistoryScreenBloc extends StatelessWidget {
  const HistoryScreenBloc({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<FoodAnalysisBloc>()..add(const LoadAllAnalyses()),
      child: const _HistoryScreenContent(),
    );
  }
}

class _HistoryScreenContent extends StatelessWidget {
  const _HistoryScreenContent();

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
            onPressed: () {
              context.read<FoodAnalysisBloc>().add(const RefreshAnalyses());
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: BlocConsumer<FoodAnalysisBloc, FoodAnalysisState>(
        listener: (context, state) {
          if (state is FoodAnalysisError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is FoodAnalysisDeleteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildFilterChips(context, state),
              if (state is FoodAnalysisLoaded) _buildStats(state),
              Expanded(
                child: _buildBody(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, FoodAnalysisState state) {
    final currentFilter =
        state is FoodAnalysisLoaded ? state.filterPeriod : 'all';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tất cả'),
            selected: currentFilter == 'all',
            onSelected: (_) {
              context.read<FoodAnalysisBloc>().add(const LoadAllAnalyses());
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Hôm nay'),
            selected: currentFilter == 'today',
            onSelected: (_) {
              context.read<FoodAnalysisBloc>().add(const LoadTodayAnalyses());
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Tuần này'),
            selected: currentFilter == 'week',
            onSelected: (_) {
              context.read<FoodAnalysisBloc>().add(const LoadWeekAnalyses());
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Tháng này'),
            selected: currentFilter == 'month',
            onSelected: (_) {
              context.read<FoodAnalysisBloc>().add(const LoadMonthAnalyses());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats(FoodAnalysisLoaded state) {
    if (state.analyses.isEmpty) return const SizedBox();

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
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Hàng đầu tiên: Bữa ăn, Calories, GI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.restaurant,
                label: 'Bữa ăn',
                value: '${state.totalCount}',
              ),
              _StatItem(
                icon: Icons.local_fire_department,
                label: 'TB Calo',
                value: state.averageCalories.toStringAsFixed(0),
              ),
              _StatItem(
                icon: Icons.speed,
                label: 'TB GI',
                value: state.averageGI.toStringAsFixed(1),
              ),
            ],
          ),
          // Kiểm tra xem có dữ liệu dinh dưỡng không
          if (state.averageProtein > 0 ||
              state.averageCarbs > 0 ||
              state.averageFat > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white30, thickness: 1),
            const SizedBox(height: 12),
            // Hàng thứ hai: Protein, Carbs, Fat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.fitness_center,
                  label: 'TB Protein',
                  value: '${state.averageProtein.toStringAsFixed(1)}g',
                  iconSize: 24,
                ),
                _StatItem(
                  icon: Icons.rice_bowl,
                  label: 'TB Carbs',
                  value: '${state.averageCarbs.toStringAsFixed(1)}g',
                  iconSize: 24,
                ),
                _StatItem(
                  icon: Icons.water_drop,
                  label: 'TB Fat',
                  value: '${state.averageFat.toStringAsFixed(1)}g',
                  iconSize: 24,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FoodAnalysisState state) {
    if (state is FoodAnalysisLoading ||
        state is FoodAnalysisOperationInProgress) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is FoodAnalysisLoaded) {
      if (state.analyses.isEmpty) {
        return Center(
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
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<FoodAnalysisBloc>().add(const RefreshAnalyses());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: state.analyses.length,
          itemBuilder: (context, index) {
            final analysis = state.analyses[index];
            return FoodAnalysisCard(
              analysis: analysis,
              onDelete: () => _deleteAnalysis(context, analysis.id),
              onTap: () {
                // Navigate to detail screen với BLoC provider mới
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<FoodAnalysisBloc>(),
                      child: FoodAnalysisDetailScreen(analysis: analysis),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    // Error or initial state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<FoodAnalysisBloc>().add(const LoadAllAnalyses());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnalysis(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa phân tích này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<FoodAnalysisBloc>().add(DeleteAnalysis(id));
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double iconSize;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: iconSize),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: iconSize == 32 ? 24 : 18,
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
