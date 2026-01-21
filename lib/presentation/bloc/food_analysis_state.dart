import 'package:equatable/equatable.dart';
import '../../domain/entities/food_analysis_entity.dart';

/// Base state cho FoodAnalysisBloc
abstract class FoodAnalysisState extends Equatable {
  const FoodAnalysisState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FoodAnalysisInitial extends FoodAnalysisState {
  const FoodAnalysisInitial();
}

/// Loading state
class FoodAnalysisLoading extends FoodAnalysisState {
  const FoodAnalysisLoading();
}

/// Loaded state với data
class FoodAnalysisLoaded extends FoodAnalysisState {
  final List<FoodAnalysisEntity> analyses;
  final String filterPeriod; // all, today, week, month

  const FoodAnalysisLoaded({
    required this.analyses,
    this.filterPeriod = 'all',
  });

  @override
  List<Object?> get props => [analyses, filterPeriod];

  /// Computed properties
  int get totalCount => analyses.length;

  double get totalCalories => analyses.fold(
        0.0,
        (sum, analysis) => sum + analysis.totalCalories,
      );

  double get averageCalories =>
      analyses.isEmpty ? 0 : totalCalories / analyses.length;

  double get averageGI => analyses.isEmpty
      ? 0
      : analyses.fold(
            0.0,
            (sum, analysis) => sum + (analysis.averageGI ?? 0),
          ) /
          analyses.length;

  // Tổng Protein (grams)
  double get totalProtein => analyses.fold(
        0.0,
        (sum, analysis) => sum + analysis.totalProtein,
      );

  // Trung bình Protein mỗi bữa ăn
  double get averageProtein =>
      analyses.isEmpty ? 0 : totalProtein / analyses.length;

  // Tổng Carbs (grams)
  double get totalCarbs => analyses.fold(
        0.0,
        (sum, analysis) => sum + analysis.totalCarbs,
      );

  // Trung bình Carbs mỗi bữa ăn
  double get averageCarbs =>
      analyses.isEmpty ? 0 : totalCarbs / analyses.length;

  // Tổng Fat (grams)
  double get totalFat => analyses.fold(
        0.0,
        (sum, analysis) => sum + analysis.totalFat,
      );

  // Trung bình Fat mỗi bữa ăn
  double get averageFat => analyses.isEmpty ? 0 : totalFat / analyses.length;

  /// CopyWith for immutability
  FoodAnalysisLoaded copyWith({
    List<FoodAnalysisEntity>? analyses,
    String? filterPeriod,
  }) {
    return FoodAnalysisLoaded(
      analyses: analyses ?? this.analyses,
      filterPeriod: filterPeriod ?? this.filterPeriod,
    );
  }
}

/// Error state
class FoodAnalysisError extends FoodAnalysisState {
  final String message;

  const FoodAnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Delete success state
class FoodAnalysisDeleteSuccess extends FoodAnalysisState {
  final String message;

  const FoodAnalysisDeleteSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Operation in progress (for delete operations)
class FoodAnalysisOperationInProgress extends FoodAnalysisState {
  const FoodAnalysisOperationInProgress();
}
