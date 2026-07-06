// lib/features/scan/data/scan_model.dart

class NutritionData {
  final double calories;
  final double carbohydrates;
  final double protein;
  final double fat;

  const NutritionData({
    required this.calories,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
  });

  factory NutritionData.fromJson(Map<String, dynamic> j) {
    return NutritionData(
      calories: (j['calories'] as num).toDouble(),
      carbohydrates: (j['carbohydrates'] as num).toDouble(),
      protein: (j['protein'] as num).toDouble(),
      fat: (j['fat'] as num).toDouble(),
    );
  }
}

class WarningData {
  final String level;
  final String label;
  final String color;
  final List<String> reasons;

  const WarningData({
    required this.level,
    required this.label,
    required this.color,
    required this.reasons,
  });

  factory WarningData.fromJson(Map<String, dynamic> j) {
    return WarningData(
      level: j['level'],
      label: j['label'],
      color: j['color'],
      reasons: List<String>.from(j['reasons'] ?? []),
    );
  }
}

class FoodItem {
  final int scanId;
  final int foodId;
  final String detectedLabel;
  final String foodName;
  final double confidencePct;
  final double portionG;
  final NutritionData nutrition;
  final WarningData warning;

  const FoodItem({
    required this.scanId,
    required this.foodId,
    required this.detectedLabel,
    required this.foodName,
    required this.confidencePct,
    required this.portionG,
    required this.nutrition,
    required this.warning,
  });

  factory FoodItem.fromJson(Map<String, dynamic> j) {
    return FoodItem(
      scanId: j['scan_id'],
      foodId: j['food_id'],
      detectedLabel: j['detected_label'],
      foodName: j['food_name'],
      confidencePct: (j['confidence_pct'] as num).toDouble(),
      portionG: (j['portion_g'] as num).toDouble(),
      nutrition: NutritionData.fromJson(j['nutrition']),
      warning: WarningData.fromJson(j['warning']),
    );
  }
}

class ScanFood {
  final int scanId;
  final String foodName;
  final String detectedLabel;
  final double confidencePct;
  final NutritionData nutrition;
  final WarningData warning;

  const ScanFood({
    required this.scanId,
    required this.foodName,
    required this.detectedLabel,
    required this.confidencePct,
    required this.nutrition,
    required this.warning,
  });

  factory ScanFood.fromJson(Map<String, dynamic> j) {
    return ScanFood(
      scanId: j['scan_id'],
      foodName: j['food_name'],
      detectedLabel: j['detected_label'],
      confidencePct: (j['confidence_pct'] as num).toDouble(),
      nutrition: NutritionData.fromJson(j['nutrition']),
      warning: WarningData.fromJson(j['warning']),
    );
  }
}

class ScanResponse {
  final int totalObjects;

  final List<ScanFood> foods;

  final NutritionData totalNutrition;

  const ScanResponse({
    required this.totalObjects,
    required this.foods,
    required this.totalNutrition,
  });

  factory ScanResponse.fromJson(Map<String, dynamic> j) {
    return ScanResponse(
      totalObjects: j['total_objects'],
      foods: (j['foods'] as List).map((e) => ScanFood.fromJson(e)).toList(),
      totalNutrition: NutritionData.fromJson(j['total_nutrition']),
    );
  }
}
