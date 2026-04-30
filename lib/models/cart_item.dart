// Cart item model for storing items in shopping cart
import '../models/meal.dart';

class CartItem {
  Meal meal; // Not final to allow updates when stock changes
  int quantity;

  CartItem({
    required this.meal,
    this.quantity = 1,
  });

  // Calculate total price for this cart item
  double get totalPrice => meal.price * quantity;

  // Check if item is available
  bool get isAvailable => meal.isAvailable;

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mealId': meal.id,
      'quantity': quantity,
    };
  }

  // Create from map and meal
  factory CartItem.fromMap(Map<String, dynamic> map, Meal meal) {
    return CartItem(
      meal: meal,
      quantity: map['quantity'] ?? 1,
    );
  }
}

