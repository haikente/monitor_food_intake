/// Mapper để chuyển đổi label tiếng Anh (ImageNet/Food-101) sang tên món Việt trong DB
class FoodLabelMapper {
  /// Map Label -> Vietnamese Name (trong DB)
  static const Map<String, String> _labelToVietnamese = {
    // Phở and Noodles
    'soup': 'Phở bò', // Generic soup mapping
    'consomme': 'Phở gà', // Clear soup
    'hot pot': 'Lẩu thập cẩm',

    // Rice dishes
    'fried rice': 'Cơm rang thập cẩm',
    'carbonara': 'Mì ý sốt kem',
    'spaghetti squash': 'Mì ý sốt cà chua',

    // Breads & Sandwiches
    'bagel': 'Bánh mì', // Closest equivalent
    'bakery': 'Bánh mì',
    'French loaf': 'Bánh mì',
    'cheeseburger': 'Bánh mì kẹp thịt', // Fallback
    'hamburger': 'Bánh mì kẹp thịt',
    'hotdog': 'Bánh mì xúc xích',
    'sandwich': 'Bánh mì kẹp',

    // Meat
    'meat loaf': 'Chả lụa',
    'plate': 'Cơm tấm', // Generic plate of food often implies rice in context

    // Specific Asian/Vietnamese items if present in ImageNet/EfficientNet labels
    'spring roll': 'Gỏi cuốn',
    'eggroll': 'Chả giò',
    'wok': 'Rau xào',

    // Drinks & Desserts
    'espresso': 'Cà phê đen',
    'cup': 'Cà phê sữa',
    'ice cream': 'Kem',
    'orange': 'Cam',
    'banana': 'Chuối',
    'apple': 'Táo',
    'pizza': 'Pizza',

    // Add more mappings as discovered from labels.txt
  };

  /// Tìm tên món Việt tương ứng (nếu có)
  static String? getVietnameseName(String label) {
    // 1. Direct match
    if (_labelToVietnamese.containsKey(label)) {
      return _labelToVietnamese[label];
    }

    // 2. Partial match (contains)
    // Ví dụ: "hot pot, hotpot" -> "Lẩu thập cẩm"
    for (final key in _labelToVietnamese.keys) {
      if (label.contains(key)) {
        return _labelToVietnamese[key];
      }
    }

    return null;
  }
}
