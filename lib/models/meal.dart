// Meal model for storing food item information
class Meal {
  final String id;
  final String name;
  final String nameTr;
  final String description;
  final String descriptionTr;
  final double price;
  final int calories;
  final Map<String, double> nutrients; // e.g., {'protein': 25.0, 'carbs': 50.0, 'fat': 10.0}
  final List<String> allergens; // e.g., ['gluten', 'dairy', 'nuts']
  final int stock;
  final String imageUrl;
  final String category; // e.g., 'main', 'dessert', 'drink', 'salad'
  final bool isVegan;
  final bool isGlutenFree;

  Meal({
    required this.id,
    required this.name,
    this.nameTr = '',
    required this.description,
    this.descriptionTr = '',
    required this.price,
    required this.calories,
    required this.nutrients,
    required this.allergens,
    required this.stock,
    required this.imageUrl,
    required this.category,
    this.isVegan = false,
    this.isGlutenFree = false,
  });

  // Convert from Firestore document
  factory Meal.fromFirestore(Map<String, dynamic> data, String id) {
    return Meal(
      id: id,
      name: data['name'] ?? '',
      nameTr: data['nameTr'] ?? '',
      description: data['description'] ?? '',
      descriptionTr: data['descriptionTr'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      nutrients: (data['nutrients'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ) ?? {},
      allergens: List<String>.from(data['allergens'] ?? []),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      category: data['category'] ?? 'main',
      isVegan: data['isVegan'] ?? false,
      isGlutenFree: data['isGlutenFree'] ?? false,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameTr': nameTr,
      'description': description,
      'descriptionTr': descriptionTr,
      'price': price,
      'calories': calories,
      'nutrients': nutrients,
      'allergens': allergens,
      'stock': stock,
      'imageUrl': imageUrl,
      'category': category,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
    };
  }

  // Check if meal is available (stock > 0)
  bool get isAvailable => stock > 0;

  // Localized helpers
  String getLocalizedName(bool isTurkish) {
    if (isTurkish) {
      return nameTr.trim().isNotEmpty ? nameTr : name;
    } else {
      return name.trim().isNotEmpty ? name : nameTr;
    }
  }

  String getLocalizedDescription(bool isTurkish) {
    if (isTurkish) {
      return descriptionTr.trim().isNotEmpty ? descriptionTr : description;
    } else {
      return description.trim().isNotEmpty ? description : descriptionTr;
    }
  }
}
