import 'package:equatable/equatable.dart';

/// Base event cho FoodAnalysisBloc
abstract class FoodAnalysisEvent extends Equatable {
  const FoodAnalysisEvent();

  @override
  List<Object?> get props => [];
}

/// Load tất cả analyses
class LoadAllAnalyses extends FoodAnalysisEvent {
  const LoadAllAnalyses();
}

/// Load analyses hôm nay
class LoadTodayAnalyses extends FoodAnalysisEvent {
  const LoadTodayAnalyses();
}

/// Load analyses tuần này
class LoadWeekAnalyses extends FoodAnalysisEvent {
  const LoadWeekAnalyses();
}

/// Load analyses tháng này
class LoadMonthAnalyses extends FoodAnalysisEvent {
  const LoadMonthAnalyses();
}

/// Xóa một analysis
class DeleteAnalysis extends FoodAnalysisEvent {
  final String id;

  const DeleteAnalysis(this.id);

  @override
  List<Object?> get props => [id];
}

/// Xóa nhiều analyses
class DeleteMultipleAnalyses extends FoodAnalysisEvent {
  final List<String> ids;

  const DeleteMultipleAnalyses(this.ids);

  @override
  List<Object?> get props => [ids];
}

/// Refresh data
class RefreshAnalyses extends FoodAnalysisEvent {
  const RefreshAnalyses();
}

/// Search analyses
class SearchAnalyses extends FoodAnalysisEvent {
  final String keyword;

  const SearchAnalyses(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

/// Update notes của analysis
class UpdateAnalysisNotes extends FoodAnalysisEvent {
  final String id;
  final String notes;

  const UpdateAnalysisNotes({
    required this.id,
    required this.notes,
  });

  @override
  List<Object?> get props => [id, notes];
}
