/// Enum định nghĩa tất cả categories trong database
/// Type-safe và tránh lỗi chính tả
enum FoodCategory {
  // ===== NHÓM NGŨ CỐC & TINH BỘT =====
  nguCoc('Ngũ cốc', '🍚', FoodCategoryGroup.carbsStarch),
  tinhBot('Tinh bột', '🍚', FoodCategoryGroup.carbsStarch),

  // ===== NHÓM SỮA =====
  sua('Sữa', '🥛', FoodCategoryGroup.dairy),

  // ===== NHÓM BÁNH KẸO & ĐỒ ĂN VẶT =====
  doNgot(
      'Đồ ngọt(đường, bánh, mứt, kẹo)', '🍬', FoodCategoryGroup.snacksDesserts),

  // ===== NHÓM GIA VỊ =====
  giaViNuocCham('Gia vị, nước chấm', '🌿', FoodCategoryGroup.seasonings),

  // ===== NHÓM THỨC UỐNG =====
  thucUongDoUongCoCon('Nước giải khát', '🍺', FoodCategoryGroup.beverages),

  // ===== NHÓM MÓN CHÍNH & ĂN VẶT NÓNG =====

  monAnTruyenThong('Thức ăn truyền thống', '🥙', FoodCategoryGroup.mainDishes),

  // ===== NHÓM ĐỒ HỘP =====
  thitDoHop('Đồ hộp', '🥫', FoodCategoryGroup.canned);

  const FoodCategory(this.displayName, this.icon, this.group);

  final String displayName;
  final String icon;
  final FoodCategoryGroup group;

  /// Tìm category từ string (case-insensitive)
  static FoodCategory? fromString(String categoryName) {
    try {
      return FoodCategory.values.firstWhere(
        (cat) => cat.displayName.toLowerCase() == categoryName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Lấy tất cả categories theo nhóm
  static List<FoodCategory> getByGroup(FoodCategoryGroup group) {
    return FoodCategory.values.where((cat) => cat.group == group).toList();
  }

  /// Lấy danh sách unique display names (để so sánh với database)
  static Set<String> getAllDisplayNames() {
    return FoodCategory.values.map((cat) => cat.displayName).toSet();
  }
}

/// Nhóm category lớn - để tổ chức UI
enum FoodCategoryGroup {
  carbsStarch('Ngũ cốc & Tinh bột', '🌾'),
  dairy('Sữa & Chế phẩm sữa', '🥛'),
  snacksDesserts('Bánh kẹo & Đồ ăn vặt', '🍰'),
  seasonings('Gia vị & Nước chấm', '🧂'),
  beverages('Thức uống', '🥤'),
  mainDishes('Món chính & Ăn vặt nóng', '🍲'),
  canned('Đồ hộp', '🥫');

  const FoodCategoryGroup(this.displayName, this.icon);

  final String displayName;
  final String icon;
}

/// Extension methods cho FoodCategory
extension FoodCategoryExtension on FoodCategory {
  /// Emoji + Display name
  String get label => '$icon $displayName';

  /// Màu sắc cho UI (có thể dùng trong Flutter)
  String get colorHex {
    switch (group) {
      case FoodCategoryGroup.carbsStarch:
        return '#FFA726'; // Orange
      case FoodCategoryGroup.dairy:
        return '#42A5F5'; // Blue
      case FoodCategoryGroup.snacksDesserts:
        return '#EC407A'; // Pink
      case FoodCategoryGroup.seasonings:
        return '#66BB6A'; // Green
      case FoodCategoryGroup.beverages:
        return '#26C6DA'; // Cyan
      case FoodCategoryGroup.mainDishes:
        return '#EF5350'; // Red
      case FoodCategoryGroup.canned:
        return '#AB47BC'; // Purple
    }
  }

  /// Priority cho sorting (nhóm quan trọng hiển thị trước)
  int get priority {
    switch (group) {
      case FoodCategoryGroup.carbsStarch:
        return 1;
      case FoodCategoryGroup.mainDishes:
        return 2;
      case FoodCategoryGroup.dairy:
        return 3;
      case FoodCategoryGroup.snacksDesserts:
        return 4;
      case FoodCategoryGroup.beverages:
        return 5;
      case FoodCategoryGroup.seasonings:
        return 6;
      case FoodCategoryGroup.canned:
        return 7;
    }
  }
}

/// Helper class để quản lý categories
class CategoryManager {
  /// Đếm số món theo category từ database
  static Map<String, int> countByCategory(Map<String, dynamic> foods) {
    final counts = <String, int>{};
    for (var food in foods.values) {
      final category = food.category as String;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  /// Validate xem có category nào chưa được định nghĩa không
  static List<String> findUndefinedCategories(Map<String, dynamic> foods) {
    final definedCategories = FoodCategory.getAllDisplayNames();
    final usedCategories = <String>{};

    for (var food in foods.values) {
      usedCategories.add(food.category as String);
    }

    return usedCategories
        .where((cat) => !definedCategories.contains(cat))
        .toList();
  }

  /// Tạo map từ category name → FoodCategory enum
  static Map<String, FoodCategory> getCategoryMap() {
    final map = <String, FoodCategory>{};
    for (var category in FoodCategory.values) {
      map[category.displayName] = category;
    }
    return map;
  }

  /// Sort categories theo group priority và count
  static List<MapEntry<String, int>> sortByPriorityAndCount(
    Map<String, int> categoryCounts,
  ) {
    final categoryMap = getCategoryMap();
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) {
        final catA = categoryMap[a.key];
        final catB = categoryMap[b.key];

        // Nếu không tìm thấy trong enum, đẩy xuống cuối
        if (catA == null && catB == null) return 0;
        if (catA == null) return 1;
        if (catB == null) return -1;

        // Sort theo priority của group trước
        final priorityCompare = catA.priority.compareTo(catB.priority);
        if (priorityCompare != 0) return priorityCompare;

        // Trong cùng group, sort theo count giảm dần
        return b.value.compareTo(a.value);
      });

    return sorted;
  }
}
