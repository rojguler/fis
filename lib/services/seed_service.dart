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
        'descriptionTr': 'Taze ızgara tavuk göğsü, pilav ve salata ile servis edilir.',
        'price': 145.0, 'calories': 350, 'stock': 25,
        'category': 'main', 'imageUrl': 'assets/images/grilledchicken.jpeg',
        'nutrients': {'protein': 35.0, 'carbs': 45.0, 'fat': 8.0},
        'allergens': [], 'isVegan': false, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Meatballs',
        'nameTr': 'Anne Köftesi',
        'description': 'Handmade meatballs with french fries and tzatziki.',
        'descriptionTr': 'Ev yapımı köfte, patates kızartması ve cacık ile.',
        'price': 150.0, 'calories': 420, 'stock': 20,
        'category': 'main', 'imageUrl': 'assets/images/meatballs.jpeg',
        'nutrients': {'protein': 28.0, 'carbs': 38.0, 'fat': 15.0},
        'allergens': ['gluten', 'dairy'], 'isVegan': false, 'isGlutenFree': false,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Manti',
        'nameTr': 'Kayseri Mantısı',
        'description': 'Homemade manti with yogurt and butter sauce.',
        'descriptionTr': 'Yoğurt ve tereyağı soslu ev yapımı mantı.',
        'price': 140.0, 'calories': 380, 'stock': 30,
        'category': 'main', 'imageUrl': 'assets/images/manti.jpeg',
        'nutrients': {'protein': 18.0, 'carbs': 55.0, 'fat': 12.0},
        'allergens': ['gluten', 'dairy', 'eggs'], 'isVegan': false, 'isGlutenFree': false,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Vegetable Meal',
        'nameTr': 'Zeytinyağlı Sebze',
        'description': 'Healthy meal prepared with fresh seasonal vegetables.',
        'descriptionTr': 'Taze mevsim sebzeleriyle hazırlanmış sağlıklı yemek.',
        'price': 135.0, 'calories': 180, 'stock': 15,
        'category': 'main', 'imageUrl': 'assets/images/vegetablemeal.jpeg',
        'nutrients': {'protein': 8.0, 'carbs': 25.0, 'fat': 5.0},
        'allergens': [], 'isVegan': true, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Lahmacun',
        'nameTr': 'Lahmacun',
        'description': 'Minced meat and spice mixture on thin dough.',
        'descriptionTr': 'İnce hamur üzerine kıyma ve baharat karışımı.',
        'price': 125.0, 'calories': 280, 'stock': 40,
        'category': 'main', 'imageUrl': 'assets/images/lahmacun.jpeg',
        'nutrients': {'protein': 12.0, 'carbs': 42.0, 'fat': 8.0},
        'allergens': ['gluten'], 'isVegan': false, 'isGlutenFree': false,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Lentil Soup',
        'nameTr': 'Mercimek Çorbası',
        'description': 'Traditional red lentil soup served with lemon and red pepper.',
        'descriptionTr': 'Geleneksel kırmızı mercimek çorbası, limon ve kırmızı biber ile servis edilir.',
        'price': 55.0, 'calories': 180, 'stock': 50,
        'category': 'soup', 'imageUrl': 'assets/images/soup.jpeg',
        'nutrients': {'protein': 10.0, 'carbs': 28.0, 'fat': 3.0},
        'allergens': [], 'isVegan': true, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Shepherd Salad',
        'nameTr': 'Çoban Salatası',
        'description': 'Chopped tomatoes, cucumbers, onions, and parsley with lemon dressing.',
        'descriptionTr': 'Doğranmış domates, salatalık, soğan ve maydanozlu limon soslu salata.',
        'price': 60.0, 'calories': 110, 'stock': 40,
        'category': 'salad', 'imageUrl': 'assets/images/salad.jpeg',
        'nutrients': {'protein': 2.0, 'carbs': 12.0, 'fat': 6.0},
        'allergens': [], 'isVegan': true, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Rice Pudding',
        'nameTr': 'Sütlaç',
        'description': 'Homemade creamy rice pudding with a burnt top, served cold.',
        'descriptionTr': 'Fırınlanmış ev yapımı kremamsı sütlaç, soğuk servis edilir.',
        'price': 65.0, 'calories': 220, 'stock': 30,
        'category': 'dessert', 'imageUrl': 'assets/images/ricepudding.jpeg',
        'nutrients': {'protein': 6.0, 'carbs': 38.0, 'fat': 5.0},
        'allergens': ['dairy'], 'isVegan': false, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Ayran',
        'nameTr': 'Ayran',
        'description': 'Traditional cold yogurt-based salty drink.',
        'descriptionTr': 'Geleneksel soğuk yoğurt bazlı tuzlu içecek.',
        'price': 30.0, 'calories': 65, 'stock': 100,
        'category': 'drink', 'imageUrl': 'assets/images/ayran.jpeg',
        'nutrients': {'protein': 4.0, 'carbs': 5.0, 'fat': 3.0},
        'allergens': ['dairy'], 'isVegan': false, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Water',
        'nameTr': 'Su',
        'description': 'Natural spring water, 500ml.',
        'descriptionTr': 'Doğal kaynak suyu, 500ml.',
        'price': 15.0, 'calories': 0, 'stock': 200,
        'category': 'drink', 'imageUrl': 'assets/images/su.jpeg',
        'nutrients': {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0},
        'allergens': [], 'isVegan': true, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Quinoa Salad',
        'nameTr': 'Kinoa Salatası',
        'description': 'Nutritious quinoa with fresh vegetables and lemon dressing.',
        'descriptionTr': 'Taze sebzeler ve limon soslu besleyici kinoa.',
        'price': 115.0, 'calories': 220, 'stock': 20,
        'category': 'diet', 'imageUrl': 'assets/images/salad.jpeg',
        'nutrients': {'protein': 12.0, 'carbs': 35.0, 'fat': 6.0},
        'allergens': [], 'isVegan': true, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
      {
        'name': 'Grilled Salmon',
        'nameTr': 'Izgara Somon',
        'description': 'Omega-3 rich grilled salmon with steamed broccoli.',
        'descriptionTr': 'Buharda pişmiş brokoli ile omega-3 zengini ızgara somon.',
        'price': 185.0, 'calories': 310, 'stock': 15,
        'category': 'diet', 'imageUrl': 'assets/images/grilledchicken.jpeg',
        'nutrients': {'protein': 32.0, 'carbs': 5.0, 'fat': 18.0},
        'allergens': ['fish'], 'isVegan': false, 'isGlutenFree': true,
        'supplierEmail': 'supplier@example.com'
      },
    ];
  }
}
