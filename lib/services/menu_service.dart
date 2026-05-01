import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal.dart';
import 'email_service.dart';

// Service for managing menu and meal data from Firebase
class MenuService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Meal> _meals = [];
  List<Meal> _todayMeals = [];
  bool _isLoading = false;

  // Stream subscriptions for real-time updates
  Stream<QuerySnapshot>? _mealsStream;

  List<Meal> get meals => _meals;
  List<Meal> get todayMeals => _todayMeals;
  bool get isLoading => _isLoading;

  // Initialize real-time listener for meals
  void initMealsListener() {
    _isLoading = true;
    notifyListeners();

    try {
      _mealsStream = _firestore.collection('meals').snapshots();
      _mealsStream!.listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final validMeals = <Meal>[];
            for (final doc in snapshot.docs) {
              final meal = Meal.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id);
              final name = meal.name.trim();
              // Auto-delete test/invalid products (empty name or all same char like "fffff")
              final isTestProduct = name.isEmpty ||
                  (name.length > 1 && name.split('').every((c) => c == name[0]));
              if (isTestProduct) {
                debugPrint('Auto-deleting test product: "$name"');
                _firestore.collection('meals').doc(doc.id).delete();
              } else {
                validMeals.add(meal);
              }
            }
            _meals = validMeals;
          } else {
            _meals = [];
          }
          _isLoading = false;
          notifyListeners();
          // Also refresh today's menu when meals change
          fetchTodayMenu();
        },
        onError: (e) {
          debugPrint('Error in meals stream: $e');
          _meals = [];
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error setting up meals listener: $e');
      _meals = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all meals (one-time, also used for refreshing)
  Future<void> fetchAllMeals() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('meals').get().timeout(const Duration(seconds: 5));
      _meals = snapshot.docs.map((doc) => Meal.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error fetching meals: $e');
      _meals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch today's menu meals
  Future<void> fetchTodayMenu() async {
    _isLoading = true;
    notifyListeners();

    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final menuSnapshot = await _firestore
          .collection('menus')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayStart.add(const Duration(days: 1))))
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (menuSnapshot.docs.isNotEmpty) {
        final menuData = menuSnapshot.docs.first.data();
        final mealIds = List<String>.from(menuData['mealIds'] ?? []);

        if (mealIds.isNotEmpty) {
          final mealsSnapshot = await _firestore
              .collection('meals')
              .where(FieldPath.documentId, whereIn: mealIds)
              .get()
              .timeout(const Duration(seconds: 5));
          
          _todayMeals = mealsSnapshot.docs
              .map((doc) => Meal.fromFirestore(doc.data(), doc.id))
              .toList();
        }
      } else {
        _todayMeals = [];
      }
    } catch (e) {
      debugPrint('Error fetching today menu: $e');
      _todayMeals = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Seed the database with initial products (Admin only)
  Future<void> seedDatabase() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final samples = _getSampleMeals();
      for (var meal in samples) {
        final existing = await _firestore.collection('meals')
            .where('name', isEqualTo: meal.name)
            .limit(1)
            .get();
        
        if (existing.docs.isEmpty) {
          await _firestore.collection('meals').add(meal.toFirestore());
        }
      }
      await fetchAllMeals();
    } catch (e) {
      debugPrint('Error seeding database: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get sample meals for testing
  List<Meal> _getSampleMeals() {
    return [
      Meal(
        id: '1',
        name: 'Grilled Chicken',
        nameTr: 'Izgara Tavuk',
        description: 'Fresh grilled chicken breast, served with rice and salad.',
        descriptionTr: 'Taze ızgara tavuk göğsü, pilav ve salata ile servis edilir.',
        price: 45.00,
        calories: 350,
        nutrients: {'protein': 35.0, 'carbs': 45.0, 'fat': 8.0},
        allergens: ['gluten'],
        stock: 25,
        imageUrl: 'assets/images/grilled_chicken.jpg',
        category: 'main',
      ),
      Meal(
        id: '2',
        name: 'Meatballs',
        nameTr: 'Anne Köftesi',
        description: 'Handmade meatballs with french fries and tzatziki.',
        descriptionTr: 'Ev yapımı köfte, patates kızartması ve cacık ile.',
        price: 50.00,
        calories: 420,
        nutrients: {'protein': 28.0, 'carbs': 38.0, 'fat': 15.0},
        allergens: ['gluten', 'dairy'],
        stock: 20,
        imageUrl: 'assets/images/meatballs.jpg',
        category: 'main',
      ),
      Meal(
        id: '3',
        name: 'Manti',
        nameTr: 'Kayseri Mantısı',
        description: 'Homemade manti with yogurt and butter sauce.',
        descriptionTr: 'Yoğurt ve tereyağı soslu ev yapımı mantı.',
        price: 40.00,
        calories: 380,
        nutrients: {'protein': 18.0, 'carbs': 55.0, 'fat': 12.0},
        allergens: ['gluten', 'dairy', 'eggs'],
        stock: 30,
        imageUrl: 'assets/images/turkish_manti.jpg',
        category: 'main',
      ),
      Meal(
        id: '4',
        name: 'Vegetable Meal',
        nameTr: 'Zeytinyağlı Sebze',
        description: 'Healthy meal prepared with fresh seasonal vegetables.',
        descriptionTr: 'Taze mevsim sebzeleriyle hazırlanmış sağlıklı yemek.',
        price: 35.00,
        calories: 180,
        nutrients: {'protein': 8.0, 'carbs': 25.0, 'fat': 5.0},
        allergens: [],
        stock: 15,
        imageUrl: 'assets/images/vegetable_stew.jpg',
        category: 'main',
      ),
      Meal(
        id: '5',
        name: 'Lahmacun',
        nameTr: 'Lahmacun',
        description: 'Minced meat and spice mixture on thin dough.',
        descriptionTr: 'İnce hamur üzerine kıyma ve baharat karışımı.',
        price: 25.00,
        calories: 280,
        nutrients: {'protein': 12.0, 'carbs': 42.0, 'fat': 8.0},
        allergens: ['gluten'],
        stock: 40,
        imageUrl: 'assets/images/lahmacun.jpg',
        category: 'main',
      ),
      Meal(
        id: '6',
        name: 'Soup',
        nameTr: 'Günün Çorbası',
        description: 'Daily fresh soup (Lentil, Yayla, Tomato etc.)',
        descriptionTr: 'Günlük taze çorba (Mercimek, Yayla, Domates vb.)',
        price: 15.00,
        calories: 120,
        nutrients: {'protein': 6.0, 'carbs': 20.0, 'fat': 2.0},
        allergens: ['gluten'],
        stock: 50,
        imageUrl: 'assets/images/lentil_soup.jpg',
        category: 'soup',
      ),
      Meal(
        id: '7',
        name: 'Salad',
        nameTr: 'Mevsim Salatası',
        description: 'Fresh greens, tomato, cucumber and olive oil dressing.',
        descriptionTr: 'Taze yeşillikler, domates, salatalık ve zeytinyağı sosu.',
        price: 20.00,
        calories: 80,
        nutrients: {'protein': 3.0, 'carbs': 10.0, 'fat': 4.0},
        allergens: [],
        stock: 35,
        imageUrl: 'assets/images/salad.jpeg',
        category: 'salad',
      ),
      Meal(
        id: '8',
        name: 'Rice Pudding',
        nameTr: 'Fırın Sütlaç',
        description: 'Homemade rice pudding, served with cinnamon.',
        descriptionTr: 'Tarçın ile servis edilen ev yapımı sütlaç.',
        price: 18.00,
        calories: 220,
        nutrients: {'protein': 6.0, 'carbs': 38.0, 'fat': 5.0},
        allergens: ['dairy', 'gluten'],
        stock: 25,
        imageUrl: 'assets/images/ricepudding.jpeg',
        category: 'dessert',
      ),
      Meal(
        id: '9',
        name: 'Ayran',
        nameTr: 'Ayran',
        description: 'Fresh ayran, 500ml.',
        descriptionTr: 'Taze ayran, 500ml.',
        price: 8.00,
        calories: 60,
        nutrients: {'protein': 4.0, 'carbs': 5.0, 'fat': 2.0},
        allergens: ['dairy'],
        stock: 100,
        imageUrl: 'assets/images/ayran.jpeg',
        category: 'drink',
      ),
      Meal(
        id: '10',
        name: 'Water',
        nameTr: 'Su',
        description: 'Natural spring water, 500ml.',
        descriptionTr: 'Doğal kaynak suyu, 500ml.',
        price: 5.00,
        calories: 0,
        nutrients: {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0},
        allergens: [],
        stock: 200,
        imageUrl: 'assets/images/su.jpeg',
        category: 'drink',
      ),
      Meal(
        id: '11',
        name: 'Quinoa Salad',
        nameTr: 'Kinoa Salatası',
        description: 'Nutritious quinoa with fresh vegetables and lemon dressing.',
        descriptionTr: 'Taze sebzeler ve limon soslu besleyici kinoa.',
        price: 35.00,
        calories: 220,
        nutrients: {'protein': 12.0, 'carbs': 35.0, 'fat': 6.0},
        allergens: [],
        stock: 20,
        imageUrl: 'assets/images/salad.jpeg',
        category: 'diet',
      ),
      Meal(
        id: '12',
        name: 'Grilled Salmon',
        nameTr: 'Izgara Somon',
        description: 'Omega-3 rich grilled salmon with steamed broccoli.',
        descriptionTr: 'Buharda pişmiş brokoli ile omega-3 zengini ızgara somon.',
        price: 85.00,
        calories: 310,
        nutrients: {'protein': 32.0, 'carbs': 5.0, 'fat': 18.0},
        allergens: ['fish'],
        stock: 15,
        imageUrl: 'assets/images/grilledchicken.jpeg',
        category: 'diet',
      ),
    ];
  }

  // Get meals by category
  List<Meal> getMealsByCategory(String category) {
    return _meals.where((meal) => meal.category == category).toList();
  }

  // Get available meals (stock > 0)
  List<Meal> getAvailableMeals() {
    return _meals.where((meal) => meal.isAvailable).toList();
  }

  // Add new meal (admin function)
  Future<void> addMeal({
    required String name,
    String nameTr = '',
    required String description,
    String descriptionTr = '',
    required double price,
    required int calories,
    required int stock,
    required String category,
    required Map<String, double> nutrients,
    required List<String> allergens,
    String imageUrl = '',
  }) async {
    try {
      final mealData = {
        'name': name,
        'nameTr': nameTr,
        'description': description,
        'descriptionTr': descriptionTr,
        'price': price,
        'calories': calories,
        'stock': stock,
        'category': category,
        'nutrients': nutrients,
        'allergens': allergens,
        'imageUrl': imageUrl,
      };

      await _firestore.collection('meals').add(mealData);
      await fetchAllMeals();
    } catch (e) {
      debugPrint('Error adding meal: $e');
      rethrow;
    }
  }

  // Update meal (admin function)
  Future<void> updateMeal({
    required String mealId,
    required String name,
    String nameTr = '',
    required String description,
    String descriptionTr = '',
    required double price,
    required int calories,
    required int stock,
    required String category,
    required Map<String, double> nutrients,
    required List<String> allergens,
    String imageUrl = '',
  }) async {
    try {
      final mealData = {
        'name': name,
        'nameTr': nameTr,
        'description': description,
        'descriptionTr': descriptionTr,
        'price': price,
        'calories': calories,
        'stock': stock,
        'category': category,
        'nutrients': nutrients,
        'allergens': allergens,
        'imageUrl': imageUrl,
      };

      await _firestore.collection('meals').doc(mealId).update(mealData);
      await fetchAllMeals();
    } catch (e) {
      debugPrint('Error updating meal: $e');
      rethrow;
    }
  }

  // Delete meal (admin function)
  Future<void> deleteMeal(String mealId) async {
    try {
      await _firestore.collection('meals').doc(mealId).delete();
      await fetchAllMeals();
    } catch (e) {
      debugPrint('Error deleting meal: $e');
      rethrow;
    }
  }

  // Create or update today's menu (admin function)
  Future<void> setTodayMenu(List<String> mealIds) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final menuSnapshot = await _firestore
          .collection('menus')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayStart.add(const Duration(days: 1))))
          .limit(1)
          .get();

      final menuData = {
        'date': Timestamp.fromDate(todayStart),
        'mealIds': mealIds,
        'cafeteriaId': 'main',
      };

      if (menuSnapshot.docs.isNotEmpty) {
        await _firestore.collection('menus').doc(menuSnapshot.docs.first.id).update(menuData);
      } else {
        await _firestore.collection('menus').add(menuData);
      }
      
      await fetchTodayMenu();

      // Yeni menü eklendiğinde tüm kullanıcılara asenkron olarak mail at
      EmailService.sendMenuUpdateEmail().catchError((e) => debugPrint("Mail hatası: \$e"));
      
    } catch (e) {
      debugPrint('Error setting today menu: $e');
      rethrow;
    }
  }

  // Quick restock meal stock (admin function)
  Future<void> quickRestock(String mealId, int amount) async {
    try {
      await _firestore.collection('meals').doc(mealId).update({
        'stock': FieldValue.increment(amount),
      });
    } catch (e) {
      debugPrint('Error restock meal: $e');
      rethrow;
    }
  }
}
