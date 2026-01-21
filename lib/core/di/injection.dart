import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/datasources/local/food_analysis_local_datasource.dart';
import '../../data/repositories/food_analysis_repository_impl.dart';
import '../../domain/repositories/food_analysis_repository.dart';
import '../../domain/usecases/delete_food_analysis.dart';
import '../../domain/usecases/get_food_analyses.dart';
import '../../domain/usecases/save_food_analysis.dart';
import '../../domain/usecases/update_food_analysis.dart';
import '../../presentation/bloc/food_analysis_bloc.dart';
import '../../services/gemini_service.dart';
import '../../services/local_food_classifier_service.dart';
import '../database/app_database.dart';

final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  
  await AppDatabase.database;

  final localClassifier = LocalFoodClassifierService();

  getIt.registerSingleton<LocalFoodClassifierService>(localClassifier);
 
  // Gemini Service (Smart Mode with Database Integration)
  final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  if (geminiApiKey.isEmpty) {
  }
  final geminiService = GeminiService(apiKey: geminiApiKey);
  getIt.registerSingleton<GeminiService>(geminiService);

  // Data Sources
  getIt.registerLazySingleton<FoodAnalysisLocalDataSource>(
    () => FoodAnalysisLocalDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<FoodAnalysisRepository>(
    () => FoodAnalysisRepositoryImpl(
      localDataSource: getIt<FoodAnalysisLocalDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(
    () => SaveFoodAnalysisUseCase(
      getIt<FoodAnalysisRepository>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetFoodAnalysesUseCase(
      getIt<FoodAnalysisRepository>(),
    ),
  );

  getIt.registerLazySingleton(
    () => UpdateFoodAnalysisUseCase(
      getIt<FoodAnalysisRepository>(),
    ),
  );

  getIt.registerLazySingleton(
    () => DeleteFoodAnalysisUseCase(
      getIt<FoodAnalysisRepository>(),
    ),
  );

  // BLoC
  getIt.registerFactory(
    () => FoodAnalysisBloc(
      getFoodAnalyses: getIt<GetFoodAnalysesUseCase>(),
      deleteFoodAnalysis: getIt<DeleteFoodAnalysisUseCase>(),
      updateFoodAnalysis: getIt<UpdateFoodAnalysisUseCase>(),
    ),
  );
}

/// Clean up dependencies (useful for testing)
Future<void> cleanupDependencies() async {
  await AppDatabase.close();
  await getIt.reset();
}
