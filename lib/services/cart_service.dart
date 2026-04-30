import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/meal.dart';
import '../services/menu_service.dart';

// Service for managing shopping cart
class CartService extends ChangeNotifier {
  static const int maxItemLimit = 999;
  
  final List<CartItem> _items = [];
  final MenuService _menuService;

  CartService(this._menuService);

  List<CartItem> get items => _items;
  
  // Get total number of items in cart
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  // Get total price of all items in cart
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  // ── Nutrition summary ──────────────────────────────────────────────────────
  int get totalCalories => _items.fold(0, (sum, item) => sum + (item.meal.calories * item.quantity));
  double get totalProtein => _items.fold(0.0, (sum, item) => sum + ((item.meal.nutrients['protein'] ?? 0.0) * item.quantity));
  double get totalCarbs => _items.fold(0.0, (sum, item) => sum + ((item.meal.nutrients['carbs'] ?? 0.0) * item.quantity));
  double get totalFat => _items.fold(0.0, (sum, item) => sum + ((item.meal.nutrients['fat'] ?? 0.0) * item.quantity));
  // Check if cart is empty
  bool get isEmpty => _items.isEmpty;
  
  // Check if cart has any unavailable items
  bool get hasUnavailableItems => _items.any((item) => !item.isAvailable);

  // Add meal to cart
  void addItem(Meal meal, {int quantity = 1}) {
    // Check if meal is available
    if (!meal.isAvailable || meal.stock <= 0) {
      debugPrint('Cannot add unavailable meal to cart');
      return;
    }

    // Check if meal already exists in cart
    final existingIndex = _items.indexWhere((item) => item.meal.id == meal.id);
    
    if (existingIndex >= 0) {
      // Update quantity if item already exists
      final existingItem = _items[existingIndex];
      var newQuantity = existingItem.quantity + quantity;
      
      // Check stock availability and max limit
      if (newQuantity > maxItemLimit) newQuantity = maxItemLimit;
      if (newQuantity > meal.stock) newQuantity = meal.stock;
      
      _items[existingIndex].quantity = newQuantity;
    } else {
      // Add new item to cart
      var startQuantity = quantity;
      if (startQuantity > maxItemLimit) startQuantity = maxItemLimit;
      if (startQuantity > meal.stock) startQuantity = meal.stock;
      
      _items.add(CartItem(meal: meal, quantity: startQuantity));
    }
    
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String mealId) {
    _items.removeWhere((item) => item.meal.id == mealId);
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String mealId, int quantity) {
    final index = _items.indexWhere((item) => item.meal.id == mealId);
    
    if (index >= 0) {
      final meal = _items[index].meal;
      
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        removeItem(mealId);
      } else {
        var newQuantity = quantity;
        if (newQuantity > maxItemLimit) newQuantity = maxItemLimit;
        if (newQuantity > meal.stock) newQuantity = meal.stock;
        
        _items[index].quantity = newQuantity;
        notifyListeners();
      }
    }
  }

  // Clear all items from cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Get cart item by meal ID
  CartItem? getItem(String mealId) {
    try {
      return _items.firstWhere((item) => item.meal.id == mealId);
    } catch (e) {
      return null;
    }
  }

  // Check if meal is in cart
  bool isInCart(String mealId) {
    return _items.any((item) => item.meal.id == mealId);
  }

  // Get quantity of a meal in cart
  int getQuantity(String mealId) {
    final item = getItem(mealId);
    return item?.quantity ?? 0;
  }

  // Refresh cart items with latest meal data (for real-time stock updates)
  void refreshCartItems() {
    final itemsToRemove = <String>[];
    
    for (var item in _items) {
      try {
        // Get latest meal data from menu service
        final latestMeal = _menuService.meals.firstWhere(
          (meal) => meal.id == item.meal.id,
        );
        
        // Update meal reference
        item.meal = latestMeal;
        
        // Adjust quantity if it exceeds new stock
        if (item.quantity > latestMeal.stock) {
          item.quantity = latestMeal.stock;
          if (item.quantity == 0) {
            itemsToRemove.add(item.meal.id);
          }
        }
      } catch (e) {
        // Meal not found, remove from cart
        itemsToRemove.add(item.meal.id);
      }
    }
    
    // Remove items that are no longer available
    for (var mealId in itemsToRemove) {
      removeItem(mealId);
    }
    
    notifyListeners();
  }
}

