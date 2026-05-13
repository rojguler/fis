import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One-time seed service to populate Firestore with localized meals.
class SeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedIfEmpty() async {
    await _seedMissing();
  }

  static Future<void> forceSeed() async {
    await _seedMissing();
  }

  static Future<void> _seedMissing() async {
    try {
      debugPrint('🌱 Firestore yerelleştirilmiş verilerle güncelleniyor...');
      
      final sampleMeals = _getMeals();
      
      // Toplu güncelleme yapalım (existing check yerine overwrite/update daha sağlam olur)
      const batchSize = 400;
      for (int i = 0; i < sampleMeals.length; i += batchSize) {
        final batch = _db.batch();
        final chunk = sampleMeals.sublist(i, (i + batchSize).clamp(0, sampleMeals.length));
        
        for (final meal in chunk) {
          // İsim bazlı kontrol et, varsa güncelle yoksa ekle
          final snap = await _db.collection('meals')
              .where('name', isEqualTo: meal['name'])
              .get();
          
          if (snap.docs.isNotEmpty) {
            batch.update(snap.docs.first.reference, meal);
          } else {
            final ref = _db.collection('meals').doc();
            batch.set(ref, meal);
          }
        }
        await batch.commit();
      }
      debugPrint('✅ Yerelleştirilmiş yemek verileri senkronize edildi.');
      await _seedTodayMenu();
    } catch (e) {
      debugPrint('❌ Seed hatası: $e');
    }
  }

  static Future<void> _seedTodayMenu() async {
    // ... (today's menu logic)
  }

  static List<Map<String, dynamic>> _getMeals() {
    return [
      {
        'name': 'Grilled Chicken',
        'nameTr': 'Izgara Tavuk',
        'description': 'Fresh grilled chicken breast, served with rice and salad.',
        'descriptionTr': 'Taze ızgara tavuk göğsü, pirinç pilavı ve salata ile servis edilir.',
        'price': 145.0, 'calories': 350, 'stock': 25,
        'category': 'main', 'imageUrl': 'assets/images/grilled_chicken.jpg',
        'nutrients': {'protein': 35.0, 'carbs': 45.0, 'fat': 8.0},
        'allergens': [], 'isVegan': false, 'isGlutenFree': true,
      },
      {
        'name': 'Lentil Soup',
        'nameTr': 'Mercimek Çorbası',
        'description': 'Traditional red lentil soup served with lemon and red pepper.',
        'descriptionTr': 'Geleneksel kırmızı mercimek çorbası, limon ve kırmızı biber ile servis edilir.',
        'price': 55.0, 'calories': 180, 'stock': 50,
        'category': 'soup', 'imageUrl': 'assets/images/lentil_soup.jpg',
        'nutrients': {'protein': 10.0, 'carbs': 28.0, 'fat': 3.0},
        'allergens': [], 'isVegan': true, 'isGlutenFree': true,
      },
      {
        'name': 'Rice Pudding',
        'nameTr': 'Sütlaç',
        'description': 'Homemade creamy rice pudding with a burnt top, served cold.',
        'descriptionTr': 'Fırınlanmış ev yapımı kremamsı sütlaç, soğuk servis edilir.',
        'price': 65.0, 'calories': 220, 'stock': 30,
        'category': 'dessert', 'imageUrl': 'assets/images/rice_pudding.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 38.0, 'fat': 5.0},
        'allergens': ['dairy'], 'isVegan': false, 'isGlutenFree': true,
      },
      {
        'name': 'Ayran',
        'nameTr': 'Ayran',
        'description': 'Traditional cold yogurt-based salty drink.',
        'descriptionTr': 'Geleneksel soğuk yoğurt bazlı tuzlu içecek.',
        'price': 30.0, 'calories': 65, 'stock': 100,
        'category': 'drink', 'imageUrl': 'assets/images/ayran.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 5.0, 'fat': 3.0},
        'allergens': ['dairy'], 'isVegan': false, 'isGlutenFree': true,
      },
      {
        'name': 'Shepherd Salad',
        'nameTr': 'Çoban Salatası',
        'description': 'Chopped tomatoes, cucumbers, onions, and parsley with lemon dressing.',
        'descriptionTr': 'Doğranmış domates, salatalık, soğan ve maydanozlu limon soslu salata.',
        'price': 60.0, 'calories': 110, 'stock': 40,
        'category': 'salad', 'imageUrl': 'assets/images/shepherd_salad.jpg',
        'nutrients': {'protein': 2.0, 'carbs': 12.0, 'fat': 6.0},
        'allergens': [], 'isVegan': true, 'isGlutenFree': true,
      },
      // ... daha fazlası eklenebilir, ancak şimdilik temel verileri güncelliyoruz.
    ];
  }
}
