import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/delete_food_analysis.dart';
import '../../domain/usecases/get_food_analyses.dart';
import '../../domain/usecases/update_food_analysis.dart';
import 'food_analysis_event.dart';
import 'food_analysis_state.dart';

/// BLoC quản lý state cho Food Analysis History
class FoodAnalysisBloc extends Bloc<FoodAnalysisEvent, FoodAnalysisState> {
  final GetFoodAnalysesUseCase getFoodAnalyses;
  final DeleteFoodAnalysisUseCase deleteFoodAnalysis;
  final UpdateFoodAnalysisUseCase updateFoodAnalysis;

  FoodAnalysisBloc({
    required this.getFoodAnalyses,
    required this.deleteFoodAnalysis,
    required this.updateFoodAnalysis,
  }) : super(const FoodAnalysisInitial()) {
    // Register event handlers
    on<LoadAllAnalyses>(_onLoadAllAnalyses);
    on<LoadTodayAnalyses>(_onLoadTodayAnalyses);
    on<LoadWeekAnalyses>(_onLoadWeekAnalyses);
    on<LoadMonthAnalyses>(_onLoadMonthAnalyses);
    on<DeleteAnalysis>(_onDeleteAnalysis);
    on<DeleteMultipleAnalyses>(_onDeleteMultipleAnalyses);
    on<RefreshAnalyses>(_onRefreshAnalyses);
    on<SearchAnalyses>(_onSearchAnalyses);
    on<UpdateAnalysisNotes>(_onUpdateAnalysisNotes);
  }

  /// Load tất cả analyses
  Future<void> _onLoadAllAnalyses(
    LoadAllAnalyses event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    emit(const FoodAnalysisLoading());
    try {
      final analyses = await getFoodAnalyses();
      emit(FoodAnalysisLoaded(
        analyses: analyses,
        filterPeriod: 'all',
      ));
    } catch (e) {
      emit(FoodAnalysisError('Lỗi tải dữ liệu: $e'));
    }
  }

  /// Load analyses hôm nay
  Future<void> _onLoadTodayAnalyses(
    LoadTodayAnalyses event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    emit(const FoodAnalysisLoading());
    try {
      final analyses = await getFoodAnalyses.getTodayAnalyses();
      emit(FoodAnalysisLoaded(
        analyses: analyses,
        filterPeriod: 'today',
      ));
    } catch (e) {
      emit(FoodAnalysisError('Lỗi tải dữ liệu: $e'));
    }
  }

  /// Load analyses tuần này
  Future<void> _onLoadWeekAnalyses(
    LoadWeekAnalyses event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    emit(const FoodAnalysisLoading());
    try {
      final analyses = await getFoodAnalyses.getThisWeekAnalyses();
      emit(FoodAnalysisLoaded(
        analyses: analyses,
        filterPeriod: 'week',
      ));
    } catch (e) {
      emit(FoodAnalysisError('Lỗi tải dữ liệu: $e'));
    }
  }

  /// Load analyses tháng này
  Future<void> _onLoadMonthAnalyses(
    LoadMonthAnalyses event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    emit(const FoodAnalysisLoading());
    try {
      final analyses = await getFoodAnalyses.getThisMonthAnalyses();
      emit(FoodAnalysisLoaded(
        analyses: analyses,
        filterPeriod: 'month',
      ));
    } catch (e) {
      emit(FoodAnalysisError('Lỗi tải dữ liệu: $e'));
    }
  }

  /// Xóa một analysis
  Future<void> _onDeleteAnalysis(
    DeleteAnalysis event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodAnalysisLoaded) return;

    try {
      // Delete from database
      await deleteFoodAnalysis(event.id);

      // Update state by removing deleted item
      final updatedAnalyses = currentState.analyses
          .where((analysis) => analysis.id != event.id)
          .toList();

      emit(currentState.copyWith(analyses: updatedAnalyses));
      emit(const FoodAnalysisDeleteSuccess('✅ Đã xóa thành công'));

      // Reload to keep consistent with state
      await Future.delayed(const Duration(milliseconds: 500));
      _reloadCurrentFilter(currentState.filterPeriod, emit);
    } catch (e) {
      emit(FoodAnalysisError('❌ Lỗi xóa: $e'));
    }
  }

  /// Xóa nhiều analyses
  Future<void> _onDeleteMultipleAnalyses(
    DeleteMultipleAnalyses event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodAnalysisLoaded) return;

    emit(const FoodAnalysisOperationInProgress());

    try {
      // Delete from database
      for (var id in event.ids) {
        await deleteFoodAnalysis(id);
      }

      // Update state
      final updatedAnalyses = currentState.analyses
          .where((analysis) => !event.ids.contains(analysis.id))
          .toList();

      emit(currentState.copyWith(analyses: updatedAnalyses));
      emit(FoodAnalysisDeleteSuccess('✅ Đã xóa ${event.ids.length} phân tích'));

      // Reload
      await Future.delayed(const Duration(milliseconds: 500));
      _reloadCurrentFilter(currentState.filterPeriod, emit);
    } catch (e) {
      emit(FoodAnalysisError('❌ Lỗi xóa: $e'));
    }
  }

  /// Refresh data (reload current filter)
  Future<void> _onRefreshAnalyses(
    RefreshAnalyses event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    final currentState = state;
    if (currentState is FoodAnalysisLoaded) {
      _reloadCurrentFilter(currentState.filterPeriod, emit);
    } else {
      add(const LoadAllAnalyses());
    }
  }

  /// Search analyses
  Future<void> _onSearchAnalyses(
    SearchAnalyses event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    emit(const FoodAnalysisLoading());
    try {
      final allAnalyses = await getFoodAnalyses();
      final keyword = event.keyword.toLowerCase();

      final filteredAnalyses = allAnalyses.where((analysis) {
        // Search in food names
        final hasMatchingFood = analysis.foods
            .any((food) => food.name.toLowerCase().contains(keyword));

        // Search in notes
        final hasMatchingNotes =
            analysis.notes?.toLowerCase().contains(keyword) ?? false;

        return hasMatchingFood || hasMatchingNotes;
      }).toList();

      emit(FoodAnalysisLoaded(
        analyses: filteredAnalyses,
        filterPeriod: 'search',
      ));
    } catch (e) {
      emit(FoodAnalysisError('Lỗi tìm kiếm: $e'));
    }
  }

  /// Update notes của analysis
  Future<void> _onUpdateAnalysisNotes(
    UpdateAnalysisNotes event,
    Emitter<FoodAnalysisState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FoodAnalysisLoaded) return;

    try {
      // Tìm analysis cần update
      final analysis = currentState.analyses.firstWhere(
        (a) => a.id == event.id,
      );

      // Update notes
      final updatedAnalysis = analysis.copyWith(notes: event.notes);

      // Call use case
      await updateFoodAnalysis(updatedAnalysis);

      // Update local state
      final updatedAnalyses = currentState.analyses.map((a) {
        return a.id == event.id ? updatedAnalysis : a;
      }).toList();

      emit(currentState.copyWith(analyses: updatedAnalyses));

      // Show success message
      emit(const FoodAnalysisDeleteSuccess('✅ Đã cập nhật ghi chú'));

      // Reload to sync
      await Future.delayed(const Duration(milliseconds: 300));
      _reloadCurrentFilter(currentState.filterPeriod, emit);
    } catch (e) {
      emit(FoodAnalysisError('❌ Lỗi cập nhật: $e'));
    }
  }

  /// Helper: Reload based on current filter
  void _reloadCurrentFilter(
    String filterPeriod,
    Emitter<FoodAnalysisState> emit,
  ) {
    switch (filterPeriod) {
      case 'today':
        add(const LoadTodayAnalyses());
        break;
      case 'week':
        add(const LoadWeekAnalyses());
        break;
      case 'month':
        add(const LoadMonthAnalyses());
        break;
      default:
        add(const LoadAllAnalyses());
    }
  }
}
