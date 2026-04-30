import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One-time seed service to populate Firestore with 100 meals.
/// Call seedIfEmpty() once from the app (e.g., admin panel or initState).
class SeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Checks if the 'meals' collection is empty and seeds it if necessary.
  static Future<void> seedIfEmpty() async {
    await _seedMissing();
  }

  /// Seeds all missing sample meals without deleting existing data.
  static Future<void> forceSeed() async {
    await _seedMissing();
  }

  static Future<void> _seedMissing() async {
    try {
      debugPrint('🌱 Firestore kontrol ediliyor...');
      final snap = await _db.collection('meals').get();
      final existingNames = snap.docs.map((doc) => (doc.data()['name'] ?? '').toString().trim().toLowerCase()).toSet();
      
      final sampleMeals = _getMeals();
      final missingMeals = sampleMeals.where((m) => !existingNames.contains((m['name'] ?? '').toString().trim().toLowerCase())).toList();
      
      if (missingMeals.isNotEmpty) {
        debugPrint('🌱 Firestore eksik yemekler yükleniyor (${missingMeals.length} adet)...');
        // Write in batches of 400 (Firestore limit is 500)
        const batchSize = 400;
        for (int i = 0; i < missingMeals.length; i += batchSize) {
          final batch = _db.batch();
          final chunk = missingMeals.sublist(i, (i + batchSize).clamp(0, missingMeals.length));
          for (final meal in chunk) {
            final ref = _db.collection('meals').doc();
            batch.set(ref, meal);
          }
          await batch.commit();
          debugPrint('  → ${i + chunk.length}/${missingMeals.length} yemek yazıldı');
        }
        debugPrint('✅ Eksik yemekler yüklendi.');
      } else {
        debugPrint('ℹ️ Tüm örnek yemekler zaten mevcut.');
      }

      // Mevcut ürünlerin eksik yerelleştirmelerini düzelt
      debugPrint('🌱 Mevcut ürünlerin yerelleştirmeleri düzeltiliyor...');
      int fixedCount = 0;
      final fixBatch = _db.batch();
      
      for (final doc in snap.docs) {
        final data = doc.data();
        String name = (data['name'] ?? '').toString().trim();
        String nameTr = (data['nameTr'] ?? '').toString().trim();
        String description = (data['description'] ?? '').toString().trim();
        String descriptionTr = (data['descriptionTr'] ?? '').toString().trim();
        
        bool needsUpdate = false;
        
        if (name.isEmpty && nameTr.isNotEmpty) {
          name = nameTr;
          needsUpdate = true;
        }
        if (nameTr.isEmpty && name.isNotEmpty) {
          nameTr = name;
          needsUpdate = true;
        }
        if (description.isEmpty && descriptionTr.isNotEmpty) {
          description = descriptionTr;
          needsUpdate = true;
        }
        if (descriptionTr.isEmpty && description.isNotEmpty) {
          descriptionTr = description;
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          fixBatch.update(doc.reference, {
            'name': name,
            'nameTr': nameTr,
            'description': description,
            'descriptionTr': descriptionTr,
          });
          fixedCount++;
        }
      }
      
      if (fixedCount > 0) {
        await fixBatch.commit();
        debugPrint('✅ $fixedCount ürünün eksik yerelleştirmeleri düzeltildi.');
      } else {
        debugPrint('ℹ️ Düzeltilecek ürün bulunamadı.');
      }
      
      // Always ensure today's menu exists
      await _seedTodayMenu();
    } catch (e) {
      debugPrint('❌ Seed hatası: $e');
    }
  }

  static Future<void> _seedAll() async {
    final meals = _getMeals();
    // Write in batches of 500 (Firestore limit)
    const batchSize = 400;
    for (int i = 0; i < meals.length; i += batchSize) {
      final batch = _db.batch();
      final chunk = meals.sublist(i, (i + batchSize).clamp(0, meals.length));
      for (final meal in chunk) {
        final ref = _db.collection('meals').doc();
        batch.set(ref, meal);
      }
      await batch.commit();
      debugPrint('  → ${i + chunk.length}/${meals.length} yemek yazıldı');
    }
  }

  static List<Map<String, dynamic>> _getMeals() {
    return [
      // ── ANA YEMEKLER ──────────────────────────────────────────────
      {
        'name': 'Grilled Chicken',
        'nameTr': 'Izgara Tavuk',
        'description': 'Fresh grilled chicken breast, served with rice and salad.',
        'descriptionTr': 'Taze ızgara tavuk göğsü, pirinç pilavı ve salata ile servis edilir.',
        'price': 145.0, 'calories': 350, 'stock': 25,
        'category': 'main', 'imageUrl': 'assets/images/grilled_chicken.jpg',
        'nutrients': {'protein': 35.0, 'carbs': 45.0, 'fat': 8.0, 'fiber': 3.0},
        'allergens': [],
        'isVegan': false,
        'isGlutenFree': true,
      },
      {
        'name': 'Meatballs',
        'nameTr': 'Anne Köftesi',
        'description': 'Handmade meatballs, served with french fries and cacik.',
        'descriptionTr': 'El yapımı köfte, patates kızartması ve cacık ile servis edilir.',
        'price': 160.0, 'calories': 420, 'stock': 20,
        'category': 'main', 'imageUrl': 'assets/images/meatballs.jpg',
        'nutrients': {'protein': 28.0, 'carbs': 38.0, 'fat': 15.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy'],
        'isVegan': false,
        'isGlutenFree': false,
      },
      {
        'name': 'Turkish Manti',
        'nameTr': 'Kayseri Mantısı',
        'description': 'Handmade manti served with yogurt and butter sauce.',
        'descriptionTr': 'El yapımı mantı, yoğurt ve tereyağlı sos ile servis edilir.',
        'price': 135.0, 'calories': 380, 'stock': 30,
        'category': 'main', 'imageUrl': 'assets/images/turkish_manti.jpg',
        'nutrients': {'protein': 18.0, 'carbs': 55.0, 'fat': 12.0, 'fiber': 4.0},
        'allergens': ['gluten', 'dairy', 'eggs'],
        'isVegan': false,
        'isGlutenFree': false,
      },
      {
        'name': 'Vegetable Stew',
        'nameTr': 'Zeytinyağlı Sebze',
        'description': 'Healthy main dish prepared with fresh seasonal vegetables.',
        'descriptionTr': 'Taze mevsim sebzeleri ile hazırlanan sağlıklı ana yemek.',
        'price': 115.0, 'calories': 180, 'stock': 15,
        'category': 'main', 'imageUrl': 'assets/images/vegetable_stew.jpg',
        'nutrients': {'protein': 8.0, 'carbs': 25.0, 'fat': 5.0, 'fiber': 8.0},
        'allergens': [],
        'isVegan': true,
        'isGlutenFree': true,
      },
      {
        'name': 'Lahmacun',
        'nameTr': 'Lahmacun',
        'description': 'Traditional thin dough with minced meat and spice mixture.',
        'descriptionTr': 'İnce hamur üzerine kıymalı ve baharatlı karışım.',
        'price': 85.0, 'calories': 280, 'stock': 40,
        'category': 'main', 'imageUrl': 'assets/images/lahmacun.jpg',
        'nutrients': {'protein': 12.0, 'carbs': 42.0, 'fat': 8.0, 'fiber': 3.0},
        'allergens': ['gluten'],
        'isVegan': false,
        'isGlutenFree': false,
      },
      {
        'name': 'Kıymalı Pide',
        'description': 'Kıymalı geleneksel Türk pidesi, fırından taze.',
        'price': 125.0, 'calories': 450, 'stock': 25,
        'category': 'main', 'imageUrl': 'assets/images/kiymali_pide.jpg',
        'nutrients': {'protein': 20.0, 'carbs': 60.0, 'fat': 14.0, 'fiber': 2.5},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },
      {
        'name': 'Tavuk Şiş',
        'description': 'Marine edilmiş tavuk şiş, bulgur pilavı ve domates ile.',
        'price': 155.0, 'calories': 320, 'stock': 20,
        'category': 'main', 'imageUrl': 'assets/images/tavuk_sis.jpg',
        'nutrients': {'protein': 32.0, 'carbs': 30.0, 'fat': 10.0, 'fiber': 3.5},
        'allergens': [],
      },
      {
        'name': 'Kuzu Güveç',
        'description': 'Fırında pişirilmiş kuzu eti, patates ve sebzeler ile.',
        'price': 195.0, 'calories': 520, 'stock': 15,
        'category': 'main', 'imageUrl': 'assets/images/kuzu_guvec.png',
        'nutrients': {'protein': 38.0, 'carbs': 35.0, 'fat': 22.0, 'fiber': 4.0},
        'allergens': [],
      },
      {
        'name': 'Kıbrıs Meze Tabağı',
        'description': 'Hellim, köfte, sigara böreği ve çeşitli meze tabağı.',
        'price': 220.0, 'calories': 580, 'stock': 10,
        'category': 'main', 'imageUrl': 'assets/images/kibris_meze_tabagi.jpg',
        'nutrients': {'protein': 30.0, 'carbs': 40.0, 'fat': 26.0, 'fiber': 3.0},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },
      {
        'name': 'Kuru Fasulye',
        'description': 'Geleneksel tarif ile pişirilmiş kuru fasulye, pirinç pilavı ile.',
        'price': 95.0, 'calories': 290, 'stock': 35,
        'category': 'main', 'imageUrl': 'assets/images/kuru_fasulye.jpg',
        'nutrients': {'protein': 14.0, 'carbs': 48.0, 'fat': 4.0, 'fiber': 10.0},
        'allergens': [],
      },
      {
        'name': 'Etli Nohut',
        'description': 'Dana eti ile pişirilmiş nohut yemeği, pirinç pilavı ile.',
        'price': 110.0, 'calories': 310, 'stock': 25,
        'category': 'main', 'imageUrl': 'assets/images/etli_nohut.jpg',
        'nutrients': {'protein': 18.0, 'carbs': 42.0, 'fat': 7.0, 'fiber': 8.0},
        'allergens': [],
      },
      {
        'name': 'Balık Tava',
        'description': 'Taze levrek tava, limon ve salata ile.',
        'price': 185.0, 'calories': 280, 'stock': 10,
        'category': 'main', 'imageUrl': 'assets/images/balik_tava.jpg',
        'nutrients': {'protein': 30.0, 'carbs': 5.0, 'fat': 15.0, 'fiber': 1.0},
        'allergens': ['fish'],
      },
      {
        'name': 'Tavuk Sote',
        'description': 'Biber ve soğan ile sote edilmiş tavuk, pirinç ile servis.',
        'price': 135.0, 'calories': 340, 'stock': 20,
        'category': 'main', 'imageUrl': 'assets/images/tavuk_sote.jpg',
        'nutrients': {'protein': 30.0, 'carbs': 35.0, 'fat': 9.0, 'fiber': 3.0},
        'allergens': [],
      },
      {
        'name': 'İskender Kebap',
        'description': 'Döner et üzerine yoğurt ve domates sosu, tereyağı ile.',
        'price': 175.0, 'calories': 550, 'stock': 15,
        'category': 'main', 'imageUrl': 'assets/images/iskender.jpg',
        'nutrients': {'protein': 35.0, 'carbs': 45.0, 'fat': 20.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy'],
      },
      {
        'name': 'Midye Dolma',
        'description': 'Pirinçli iç harçla doldurulmuş midye, limon ile.',
        'price': 120.0, 'calories': 240, 'stock': 12,
        'category': 'main', 'imageUrl': 'assets/images/midye_dolma.jpg',
        'nutrients': {'protein': 15.0, 'carbs': 30.0, 'fat': 6.0, 'fiber': 2.0},
        'allergens': ['shellfish', 'gluten'],
      },
      {
        'name': 'Kalamar Tava',
        'description': 'Çıtır kalamar halkası, tzatziki sosu ve limon ile.',
        'price': 165.0, 'calories': 350, 'stock': 10,
        'category': 'main', 'imageUrl': 'assets/images/kalamar_tava.jpg',
        'nutrients': {'protein': 22.0, 'carbs': 28.0, 'fat': 14.0, 'fiber': 1.0},
        'allergens': ['shellfish', 'gluten', 'dairy'],
      },
      {
        'name': 'Tavuk Döner',
        'description': 'Lezzetli tavuk döner dürüm, acılı sos ile.',
        'price': 105.0, 'calories': 490, 'stock': 30,
        'category': 'main', 'imageUrl': 'assets/images/tavuk_doner.jpg',
        'nutrients': {'protein': 28.0, 'carbs': 55.0, 'fat': 15.0, 'fiber': 3.0},
        'allergens': ['gluten', 'dairy'],
      },
      {
        'name': 'Et Döner',
        'description': 'Dana ve kuzu karışımı döner dürüm, sarımsaklı yoğurt ile.',
        'price': 135.0, 'calories': 590, 'stock': 25,
        'category': 'main', 'imageUrl': 'assets/images/iskender.jpg',
        'nutrients': {'protein': 32.0, 'carbs': 55.0, 'fat': 22.0, 'fiber': 3.0},
        'allergens': ['gluten', 'dairy'],
      },
      {
        'name': 'Musakka',
        'description': 'Patlıcan ve kıymalı katman katman musakka, fırında pişirilmiş.',
        'price': 140.0, 'calories': 460, 'stock': 15,
        'category': 'main', 'imageUrl': 'assets/images/musakka.jpg',
        'nutrients': {'protein': 20.0, 'carbs': 28.0, 'fat': 25.0, 'fiber': 6.0},
        'allergens': ['dairy', 'eggs'],
      },
      {
        'name': 'Zeytinyağlı Enginar',
        'description': 'Zeytinyağında pişirilmiş enginar, limon ile soğuk servis.',
        'price': 125.0, 'calories': 150, 'stock': 10,
        'category': 'main', 'imageUrl': 'assets/images/zeytinyagli_enginar.jpg',
        'nutrients': {'protein': 5.0, 'carbs': 18.0, 'fat': 6.0, 'fiber': 7.0},
        'allergens': [],
        'isVegan': true,
        'isGlutenFree': true,
      },

      // ── ÇORBALAR ──────────────────────────────────────────────────
      {
        'name': 'Lentil Soup',
        'nameTr': 'Mercimek Çorbası',
        'description': 'Traditional red lentil soup served with lemon and red pepper.',
        'descriptionTr': 'Geleneksel kırmızı mercimek çorbası, limon ve kırmızı biber ile.',
        'price': 50.0, 'calories': 180, 'stock': 60,
        'category': 'soup', 'imageUrl': 'assets/images/lentil_soup.jpg',
        'nutrients': {'protein': 10.0, 'carbs': 28.0, 'fat': 3.0, 'fiber': 8.0},
        'allergens': [],
        'isVegan': true,
        'isGlutenFree': true,
      },
      {
        'name': 'Yayla Çorbası',
        'description': 'Yoğurtlu ve nane soslu pirinçli çorba.',
        'price': 50.0, 'calories': 160, 'stock': 50,
        'category': 'soup', 'imageUrl': 'assets/images/yayla_corbasi.jpg',
        'nutrients': {'protein': 7.0, 'carbs': 22.0, 'fat': 4.0, 'fiber': 1.0},
        'allergens': ['dairy', 'gluten'],
      },
      {
        'name': 'Domates Çorbası',
        'description': 'Taze domates ile hazırlanan kremalı domates çorbası.',
        'price': 50.0, 'calories': 140, 'stock': 50,
        'category': 'soup', 'imageUrl': 'assets/images/domates_corbasi.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 20.0, 'fat': 4.0, 'fiber': 3.0},
        'allergens': ['dairy'],
      },
      {
        'name': 'Ezogelin Çorbası',
        'description': 'Kırmızı mercimek, bulgur ve baharatlarla pişirilmiş.',
        'price': 50.0, 'calories': 195, 'stock': 40,
        'category': 'soup', 'imageUrl': 'assets/images/ezogelin_corbasi.jpg',
        'nutrients': {'protein': 10.0, 'carbs': 32.0, 'fat': 3.5, 'fiber': 7.0},
        'allergens': ['gluten'],
      },
      {
        'name': 'İşkembe Çorbası',
        'description': 'Geleneksel işkembe çorbası, sarımsaklı sirke ile.',
        'price': 55.0, 'calories': 210, 'stock': 20,
        'category': 'soup', 'imageUrl': 'assets/images/iskembe_corbasi.png',
        'nutrients': {'protein': 15.0, 'carbs': 10.0, 'fat': 10.0, 'fiber': 0.0},
        'allergens': ['dairy'],
      },
      {
        'name': 'Brokoli Çorbası',
        'description': 'Kremalı brokoli çorbası, taze ekmek ile servis.',
        'price': 55.0, 'calories': 150, 'stock': 30,
        'category': 'soup', 'imageUrl': 'assets/images/brokoli_corbasi.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 16.0, 'fat': 6.0, 'fiber': 5.0},
        'allergens': ['dairy'],
      },

      // ── SALATALAR ─────────────────────────────────────────────────
      {
        'name': 'Shepherd Salad',
        'nameTr': 'Çoban Salatası',
        'description': 'Fresh tomatoes, cucumbers, onions, olive oil and lemon.',
        'descriptionTr': 'Taze domates, salatalık, soğan, zeytinyağı ve limon.',
        'price': 65.0, 'calories': 80, 'stock': 40,
        'category': 'salad', 'imageUrl': 'assets/images/shepherd_salad.jpg',
        'nutrients': {'protein': 3.0, 'carbs': 10.0, 'fat': 4.0, 'fiber': 3.0},
        'allergens': [],
      },
      {
        'name': 'Sezar Salatası',
        'description': 'Marul, parmezan, kruton ve özel sezar sos ile.',
        'price': 95.0, 'calories': 180, 'stock': 20,
        'category': 'salad', 'imageUrl': 'assets/images/sezar_salatasi.jpg',
        'nutrients': {'protein': 8.0, 'carbs': 12.0, 'fat': 11.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy', 'eggs', 'fish'],
      },
      {
        'name': 'Ton Balıklı Salata',
        'description': 'Ton balığı, mısır, domates ve zeytinyağlı yeşil salata.',
        'price': 105.0, 'calories': 200, 'stock': 15,
        'category': 'salad', 'imageUrl': 'assets/images/ton_balikli_salata.jpg',
        'nutrients': {'protein': 18.0, 'carbs': 10.0, 'fat': 8.0, 'fiber': 3.0},
        'allergens': ['fish'],
      },
      {
        'name': 'Rus Salatası',
        'description': 'Patates, havuç, bezelye ve mayonezli geleneksel Rus salatası.',
        'price': 75.0, 'calories': 250, 'stock': 20,
        'category': 'salad', 'imageUrl': 'assets/images/rus_salatasi.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 28.0, 'fat': 13.0, 'fiber': 4.0},
        'allergens': ['eggs', 'dairy'],
      },
      {
        'name': 'Hellim Salatası',
        'description': 'Izgaralanmış Kıbrıs hellimi, domates ve nane ile taze salata.',
        'price': 120.0, 'calories': 220, 'stock': 15,
        'category': 'salad', 'imageUrl': 'assets/images/hellim_salatasi.jpg',
        'nutrients': {'protein': 14.0, 'carbs': 8.0, 'fat': 14.0, 'fiber': 2.0},
        'allergens': ['dairy'],
      },

      // ── TATLILAR ──────────────────────────────────────────────────
      {
        'name': 'Rice Pudding',
        'nameTr': 'Sütlaç',
        'description': 'Homemade creamy rice pudding, served with cinnamon.',
        'descriptionTr': 'Ev yapımı sütlaç, tarçın ile servis edilir.',
        'price': 60.0, 'calories': 220, 'stock': 30,
        'category': 'dessert', 'imageUrl': 'assets/images/rice_pudding.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 38.0, 'fat': 5.0, 'fiber': 0.0},
        'allergens': ['dairy', 'gluten'],
      },
      {
        'name': 'Baklava',
        'description': 'İnce yufka katları arasında fıstıklı geleneksel Türk baklavası.',
        'price': 75.0, 'calories': 400, 'stock': 25,
        'category': 'dessert', 'imageUrl': 'assets/images/baklava.jpg',
        'nutrients': {'protein': 8.0, 'carbs': 52.0, 'fat': 18.0, 'fiber': 2.0},
        'allergens': ['gluten', 'nuts', 'dairy'],
      },
      {
        'name': 'Kazandibi',
        'description': 'Karamelize kazandibi, geleneksel tarçınlı muhallebi.',
        'price': 60.0, 'calories': 250, 'stock': 20,
        'category': 'dessert', 'imageUrl': 'assets/images/kazandibi.jpg',
        'nutrients': {'protein': 7.0, 'carbs': 40.0, 'fat': 6.0, 'fiber': 0.0},
        'allergens': ['dairy', 'gluten'],
      },
      {
        'name': 'Kadayıf',
        'description': 'Tel kadayıf, kaymak ve şerbet ile geleneksel tatlı.',
        'price': 65.0, 'calories': 380, 'stock': 15,
        'category': 'dessert', 'imageUrl': 'assets/images/kadayif.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 58.0, 'fat': 14.0, 'fiber': 1.0},
        'allergens': ['gluten', 'dairy', 'nuts'],
      },
      {
        'name': 'Revani',
        'description': 'İrmikli Kıbrıs revani, şerbetli.',
        'price': 55.0, 'calories': 340, 'stock': 20,
        'category': 'dessert', 'imageUrl': 'assets/images/revani.jpg',
        'nutrients': {'protein': 5.0, 'carbs': 62.0, 'fat': 8.0, 'fiber': 1.5},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },
      {
        'name': 'Lokma',
        'description': 'Altın renkli kızarmış hamur and tatlı şerbet ile lokma.',
        'price': 45.0, 'calories': 280, 'stock': 40,
        'category': 'dessert', 'imageUrl': '',
        'nutrients': {'protein': 4.0, 'carbs': 48.0, 'fat': 8.0, 'fiber': 1.0},
        'allergens': ['gluten', 'eggs'],
      },
      {
        'name': 'Dondurma',
        'description': 'Günlük taze dondurma, çikolata veya vanilyalı.',
        'price': 45.0, 'calories': 200, 'stock': 50,
        'category': 'dessert', 'imageUrl': 'assets/images/dondurma.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 28.0, 'fat': 8.0, 'fiber': 0.0},
        'allergens': ['dairy'],
      },
      {
        'name': 'Tiramisu',
        'description': 'Mascarpone kremalı, espresso ve kakao tozlu tiramisu.',
        'price': 80.0, 'calories': 350, 'stock': 15,
        'category': 'dessert', 'imageUrl': 'assets/images/tiramisu.jpg',
        'nutrients': {'protein': 7.0, 'carbs': 38.0, 'fat': 18.0, 'fiber': 0.5},
        'allergens': ['dairy', 'eggs', 'gluten'],
      },
      {
        'name': 'Çikolatalı Brownie',
        'description': 'Sıcak çikolata soslu ve vanilya dondurmalı brownie.',
        'price': 75.0, 'calories': 420, 'stock': 20,
        'category': 'dessert', 'imageUrl': 'assets/images/cikolatali_browni.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 52.0, 'fat': 20.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy', 'eggs', 'nuts'],
      },

      // ── İÇECEKLER ─────────────────────────────────────────────────
      {
        'name': 'Ayran',
        'nameTr': 'Ayran',
        'description': 'Freshly made traditional yogurt drink, 500ml.',
        'descriptionTr': 'Taze yapılmış ayran, 500ml.',
        'price': 30.0, 'calories': 60, 'stock': 100,
        'category': 'drink', 'imageUrl': 'assets/images/ayran.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 5.0, 'fat': 2.0, 'fiber': 0.0},
        'allergens': ['dairy'],
      },
      {
        'name': 'Water',
        'nameTr': 'Su',
        'description': 'Natural spring water, 500ml.',
        'descriptionTr': 'Doğal kaynak suyu, 500ml.',
        'price': 15.0, 'calories': 0, 'stock': 200,
        'category': 'drink', 'imageUrl': 'assets/images/water.jpg',
        'nutrients': {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'fiber': 0.0},
        'allergens': [],
      },
      {
        'name': 'Turkish Tea',
        'nameTr': 'Türk Çayı',
        'description': 'Traditional brewed tea served in a glass.',
        'descriptionTr': 'Demlik çay, bardakta servis edilir.',
        'price': 15.0, 'calories': 5, 'stock': 150,
        'category': 'drink', 'imageUrl': 'assets/images/turkish_tea.jpg',
        'nutrients': {'protein': 0.0, 'carbs': 1.0, 'fat': 0.0, 'fiber': 0.0},
        'allergens': [],
      },
      {
        'name': 'Nescafé',
        'description': 'Sıcak veya soğuk Nescafé kahve.',
        'price': 35.0, 'calories': 40, 'stock': 80,
        'category': 'drink', 'imageUrl': 'assets/images/neskafe.jpg',
        'nutrients': {'protein': 1.0, 'carbs': 6.0, 'fat': 1.0, 'fiber': 0.0},
        'allergens': ['dairy'],
      },
      {
        'name': 'Türk Kahvesi',
        'description': 'Geleneksel Türk tiryaki kahvesi.',
        'price': 35.0, 'calories': 15, 'stock': 80,
        'category': 'drink', 'imageUrl': '',
        'nutrients': {'protein': 0.5, 'carbs': 2.0, 'fat': 0.0, 'fiber': 0.0},
        'allergens': [],
      },
      {
        'name': 'Taze Portakal Suyu',
        'description': 'Günlük taze sıkılmış portakal suyu, 500ml.',
        'price': 55.0, 'calories': 110, 'stock': 40,
        'category': 'drink', 'imageUrl': 'assets/images/taze_portakal_suyu.jpg',
        'nutrients': {'protein': 2.0, 'carbs': 26.0, 'fat': 0.5, 'fiber': 1.0},
        'allergens': [],
      },
      {
        'name': 'Limonata',
        'description': 'Ev yapımı taze limonata, nane ile.',
        'price': 45.0, 'calories': 80, 'stock': 60,
        'category': 'drink', 'imageUrl': 'assets/images/limonata.jpg',
        'nutrients': {'protein': 0.5, 'carbs': 20.0, 'fat': 0.0, 'fiber': 0.5},
        'allergens': [],
      },
      {
        'name': 'Cola',
        'description': 'Soğuk Coca-Cola, 330ml kutu.',
        'price': 35.0, 'calories': 140, 'stock': 100,
        'category': 'drink', 'imageUrl': 'assets/images/kola.jpg',
        'nutrients': {'protein': 0.0, 'carbs': 36.0, 'fat': 0.0, 'fiber': 0.0},
        'allergens': [],
      },
      {
        'name': 'Şalgam',
        'description': 'Geleneksel Türk turplu şalgam suyu, 250ml.',
        'price': 25.0, 'calories': 30, 'stock': 50,
        'category': 'drink', 'imageUrl': 'assets/images/salgam.png',
        'nutrients': {'protein': 1.0, 'carbs': 6.0, 'fat': 0.0, 'fiber': 0.5},
        'allergens': [],
      },
      {
        'name': 'Soda',
        'description': 'Soğuk maden sodası, 200ml.',
        'price': 20.0, 'calories': 0, 'stock': 100,
        'category': 'drink', 'imageUrl': 'assets/images/soda.jpg',
        'nutrients': {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'fiber': 0.0},
        'allergens': [],
      },
      {
        'name': 'Meyve Suyu',
        'description': 'Kutu meyve suyu, vişne/şeftali/kayısı çeşitleri.',
        'price': 25.0, 'calories': 120, 'stock': 80,
        'category': 'drink', 'imageUrl': 'assets/images/meyve_suyu.jpg',
        'nutrients': {'protein': 0.5, 'carbs': 28.0, 'fat': 0.0, 'fiber': 0.5},
        'allergens': [],
      },

      // ── ATISTIRMALIKLAR ───────────────────────────────────────────
      {
        'name': 'Sigara Böreği',
        'description': 'Peynirli veya patatesli geleneksel sigara böreği.',
        'price': 65.0, 'calories': 310, 'stock': 40,
        'category': 'snack', 'imageUrl': 'assets/images/sigara_boregi.jpg',
        'nutrients': {'protein': 9.0, 'carbs': 35.0, 'fat': 14.0, 'fiber': 1.5},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },
      {
        'name': 'Su Böreği',
        'description': 'El açması peynirli su böreği, tereyağlı.',
        'price': 85.0, 'calories': 380, 'stock': 20,
        'category': 'snack', 'imageUrl': 'assets/images/su_boregi.jpg',
        'nutrients': {'protein': 12.0, 'carbs': 42.0, 'fat': 18.0, 'fiber': 1.5},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },
      {
        'name': 'Peynirli Poğaça',
        'description': 'Zeytinli veya peynirli gevrek poğaça.',
        'price': 45.0, 'calories': 260, 'stock': 50,
        'category': 'snack', 'imageUrl': 'assets/images/peynirli_pogaca.jpg',
        'nutrients': {'protein': 7.0, 'carbs': 32.0, 'fat': 11.0, 'fiber': 1.5},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },
      {
        'name': 'Simit',
        'description': 'Susam kaplamalı geleneksel simit.',
        'price': 30.0, 'calories': 220, 'stock': 60,
        'category': 'snack', 'imageUrl': 'assets/images/simit.jpg',
        'nutrients': {'protein': 8.0, 'carbs': 40.0, 'fat': 3.0, 'fiber': 3.0},
        'allergens': ['gluten', 'sesame'],
      },
      {
        'name': 'Ispanaklı Gözleme',
        'description': 'Ispanak ve peynirli el açması Türk gözlemesi.',
        'price': 95.0, 'calories': 340, 'stock': 25,
        'category': 'snack', 'imageUrl': 'assets/images/ispanakli_gozleme.jpg',
        'nutrients': {'protein': 14.0, 'carbs': 38.0, 'fat': 14.0, 'fiber': 3.0},
        'allergens': ['gluten', 'dairy'],
      },
      {
        'name': 'Hellim Izgara',
        'description': 'Sicilyalı hellim peyniri ızgarada pişirilmiş, nane ile.',
        'price': 95.0, 'calories': 280, 'stock': 30,
        'category': 'snack', 'imageUrl': 'assets/images/hellim_izgara.jpg',
        'nutrients': {'protein': 18.0, 'carbs': 2.0, 'fat': 22.0, 'fiber': 0.0},
        'allergens': ['dairy'],
      },
      {
        'name': 'Falafel Tabağı',
        'description': 'Baharatlı nohutlu falafel, humus ve pita ekmeği ile.',
        'price': 120.0, 'calories': 380, 'stock': 15,
        'category': 'snack', 'imageUrl': 'assets/images/falafel_tabagi.jpg',
        'nutrients': {'protein': 16.0, 'carbs': 45.0, 'fat': 14.0, 'fiber': 10.0},
        'allergens': ['gluten', 'sesame'],
      },
      {
        'name': 'Humus Tabağı',
        'description': 'Ev yapımı humus, zeytinyağı ve pul biber ile pita ekmek.',
        'price': 95.0, 'calories': 260, 'stock': 25,
        'category': 'snack', 'imageUrl': 'assets/images/humus_tabagi.jpg',
        'nutrients': {'protein': 10.0, 'carbs': 32.0, 'fat': 12.0, 'fiber': 8.0},
        'allergens': ['gluten', 'sesame'],
      },
      {
        'name': 'Kaşarlı Tost',
        'description': 'Hotpres tost ekmeğinde kaşar peyniri ve salam.',
        'price': 70.0, 'calories': 350, 'stock': 30,
        'category': 'snack', 'imageUrl': 'assets/images/kasarli_tost.jpg',
        'nutrients': {'protein': 16.0, 'carbs': 36.0, 'fat': 15.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy'],
      },

      // ── KAHVALTI ──────────────────────────────────────────────────
      {
        'name': 'Türk Kahvaltısı',
        'description': 'Zeytin, peynir, domates, salatalık, bal, tereyağı ve yumurta.',
        'price': 145.0, 'calories': 450, 'stock': 20,
        'category': 'breakfast', 'imageUrl': 'assets/images/turk_kahvaltisi.jpg',
        'nutrients': {'protein': 20.0, 'carbs': 30.0, 'fat': 26.0, 'fiber': 4.0},
        'allergens': ['dairy', 'eggs', 'gluten'],
      },
      {
        'name': 'Sahanda Yumurta',
        'description': 'Tereyağında pişirilmiş sahanda yumurta, sucuklu veya sade.',
        'price': 65.0, 'calories': 220, 'stock': 30,
        'category': 'breakfast', 'imageUrl': 'assets/images/sahanda_yumurta.jpg',
        'nutrients': {'protein': 12.0, 'carbs': 2.0, 'fat': 18.0, 'fiber': 0.0},
        'allergens': ['eggs', 'dairy'],
      },
      {
        'name': 'Menemen',
        'description': 'Domates ve biber ile pişirilmiş yumurta, ekmek ile.',
        'price': 75.0, 'calories': 250, 'stock': 25,
        'category': 'breakfast', 'imageUrl': 'assets/images/menemen.jpg',
        'nutrients': {'protein': 13.0, 'carbs': 16.0, 'fat': 15.0, 'fiber': 3.0},
        'allergens': ['eggs', 'gluten'],
      },
      {
        'name': 'Omlet',
        'description': 'Peynir, domates ve biber ile omlet.',
        'price': 80.0, 'calories': 290, 'stock': 25,
        'category': 'breakfast', 'imageUrl': 'assets/images/omlet.jpg',
        'nutrients': {'protein': 18.0, 'carbs': 4.0, 'fat': 22.0, 'fiber': 1.0},
        'allergens': ['eggs', 'dairy'],
      },
      {
        'name': 'Granola Bowl',
        'description': 'Yulaf, kuru meyve ve fındıklı granola, yoğurt ve bal ile.',
        'price': 95.0, 'calories': 380, 'stock': 15,
        'category': 'breakfast', 'imageUrl': 'assets/images/granola_bowl.jpg',
        'nutrients': {'protein': 12.0, 'carbs': 58.0, 'fat': 10.0, 'fiber': 7.0},
        'allergens': ['dairy', 'gluten', 'nuts'],
      },
      {
        'name': 'Pancake',
        'description': 'Taze pankek, akçaağaç şurubu ve meyve ile.',
        'price': 90.0, 'calories': 340, 'stock': 20,
        'category': 'breakfast', 'imageUrl': 'assets/images/pankek.jpg',
        'nutrients': {'protein': 8.0, 'carbs': 56.0, 'fat': 10.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },

      // ── VEJETARYENlER ─────────────────────────────────────────────
      {
        'name': 'Mercimek Köftesi',
        'description': 'Kırmızı mercimek ve bulgurdan yapılan vejetaryen köfte.',
        'price': 85.0, 'calories': 240, 'stock': 25,
        'category': 'vegetarian', 'imageUrl': 'assets/images/mercimek_koftesi.jpg',
        'nutrients': {'protein': 10.0, 'carbs': 42.0, 'fat': 3.0, 'fiber': 8.0},
        'allergens': ['gluten'],
      },
      {
        'name': 'Zeytinyağlı Taze Fasulye',
        'description': 'Zeytinyağında taze fasulye ve domates ile.',
        'price': 90.0, 'calories': 160, 'stock': 20,
        'category': 'vegetarian', 'imageUrl': 'assets/images/zeytinyagli_taze_fasulye.jpg',
        'nutrients': {'protein': 5.0, 'carbs': 22.0, 'fat': 6.0, 'fiber': 7.0},
        'allergens': [],
      },
      {
        'name': 'İmam Bayıldı',
        'description': 'Patlıcan, domates, soğan ve sarımsaklı zeytinyağlı yemek.',
        'price': 100.0, 'calories': 200, 'stock': 15,
        'category': 'vegetarian', 'imageUrl': 'assets/images/imam_bayildi.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 24.0, 'fat': 10.0, 'fiber': 7.0},
        'allergens': [],
      },
      {
        'name': 'Zeytinyağlı Dolma',
        'description': 'Zeytinyağlı pirinçli iç harçla doldurulmuş yaprak sarması.',
        'price': 110.0, 'calories': 190, 'stock': 20,
        'category': 'vegetarian', 'imageUrl': 'assets/images/zeytinyagli_dolma.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 28.0, 'fat': 7.0, 'fiber': 3.0},
        'allergens': ['gluten'],
      },
      {
        'name': 'Avokado Toast',
        'description': 'Tam tahıllı ekmekte ezilmiş avokado, limon ve pul biber.',
        'price': 115.0, 'calories': 310, 'stock': 15,
        'category': 'vegetarian', 'imageUrl': 'assets/images/avokado_tostt.png',
        'nutrients': {'protein': 8.0, 'carbs': 30.0, 'fat': 18.0, 'fiber': 8.0},
        'allergens': ['gluten'],
      },
      {
        'name': 'Quinoa Bowl',
        'description': 'Kinoa, ızgara sebzeler, tahin sosu ve nane ile protein kasesi.',
        'price': 135.0, 'calories': 350, 'stock': 12,
        'category': 'vegetarian', 'imageUrl': 'assets/images/quinoa_bowl.jpg',
        'nutrients': {'protein': 14.0, 'carbs': 44.0, 'fat': 12.0, 'fiber': 8.0},
        'allergens': ['sesame'],
      },
      {
        'name': 'Tabbouleh',
        'description': 'Bol maydanoz, domates, limon ve zeytinyağı ile Lübnan salatası.',
        'price': 85.0, 'calories': 140, 'stock': 20,
        'category': 'vegetarian', 'imageUrl': 'assets/images/tabbouleh.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 20.0, 'fat': 6.0, 'fiber': 5.0},
        'allergens': ['gluten'],
      },
      {
        'name': 'Falafel Wrap',
        'description': 'Lavaş ekmekte falafel, tahin sosu ve sebzeler.',
        'price': 105.0, 'calories': 380, 'stock': 15,
        'category': 'vegetarian', 'imageUrl': 'assets/images/falafel_wrap.jpg',
        'nutrients': {'protein': 14.0, 'carbs': 50.0, 'fat': 14.0, 'fiber': 9.0},
        'allergens': ['gluten', 'sesame'],
      },

      // ── PILAV & YAN YEMEKLER ───────────────────────────────────────
      {
        'name': 'Pirinç Pilavı',
        'description': 'Tereyağlı sade pirinç pilavı, vermicelli ile.',
        'price': 45.0, 'calories': 200, 'stock': 80,
        'category': 'side', 'imageUrl': 'assets/images/pirinc_pilavi.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 38.0, 'fat': 5.0, 'fiber': 0.5},
        'allergens': ['dairy', 'gluten'],
      },
      {
        'name': 'Bulgur Pilavı',
        'description': 'Domatesli ve sebzeli bulgur pilavı.',
        'price': 40.0, 'calories': 190, 'stock': 70,
        'category': 'side', 'imageUrl': 'assets/images/bulgur_pilavi.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 36.0, 'fat': 4.0, 'fiber': 4.0},
        'allergens': ['gluten'],
      },
      {
        'name': 'Patates Kızartması',
        'description': 'Altın sarısı gevrek patates kızartması.',
        'price': 50.0, 'calories': 320, 'stock': 60,
        'category': 'side', 'imageUrl': 'assets/images/patates_kizartmasi.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 45.0, 'fat': 14.0, 'fiber': 3.5},
        'allergens': [],
      },
      {
        'name': 'Izgara Sebze',
        'description': 'Parmezan peynirli çeşitli ızgara sebzeler.',
        'price': 65.0, 'calories': 140, 'stock': 30,
        'category': 'side', 'imageUrl': 'assets/images/izgara_sebze.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 18.0, 'fat': 5.0, 'fiber': 6.0},
        'allergens': ['dairy'],
      },
      {
        'name': 'Ekmek',
        'description': 'Taze beyaz ekmek, 2 dilim.',
        'price': 15.0, 'calories': 140, 'stock': 120,
        'category': 'side', 'imageUrl': 'assets/images/ekmek.jpg',
        'nutrients': {'protein': 5.0, 'carbs': 28.0, 'fat': 1.5, 'fiber': 1.5},
        'allergens': ['gluten'],
      },
      {
        'name': 'Makarna',
        'description': 'Domates soslu penne makarna, parmezan ile.',
        'price': 95.0, 'calories': 380, 'stock': 25,
        'category': 'side', 'imageUrl': 'assets/images/makarna.jpg',
        'nutrients': {'protein': 14.0, 'carbs': 60.0, 'fat': 8.0, 'fiber': 3.5},
        'allergens': ['gluten', 'dairy'],
      },
      {
        'name': 'Cacık',
        'description': 'Soğuk yoğurt, salatalık, nane ve sarımsaklı cacık.',
        'price': 40.0, 'calories': 80, 'stock': 50,
        'category': 'side', 'imageUrl': 'assets/images/cacik.jpg',
        'nutrients': {'protein': 4.0, 'carbs': 8.0, 'fat': 3.0, 'fiber': 0.5},
        'allergens': ['dairy'],
      },

      // ── FASTFOOD ──────────────────────────────────────────────────
      {
        'name': 'Hamburger',
        'description': '150g dana burgeri, marul, domates ve özel sos ile.',
        'price': 155.0, 'calories': 540, 'stock': 20,
        'category': 'fastfood', 'imageUrl': 'assets/images/hamburger.jpg',
        'nutrients': {'protein': 28.0, 'carbs': 45.0, 'fat': 24.0, 'fiber': 2.5},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },
      {
        'name': 'Tavuk Burger',
        'description': 'Çıtır tavuk fileto, marul ve ranch sos ile burger.',
        'price': 130.0, 'calories': 490, 'stock': 20,
        'category': 'fastfood', 'imageUrl': 'assets/images/tavuk_burger.jpg',
        'nutrients': {'protein': 26.0, 'carbs': 48.0, 'fat': 18.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy', 'eggs'],
      },
      {
        'name': 'Hot Dog',
        'description': 'Sosisli sandviç, hardal ve ketçap ile.',
        'price': 100.0, 'calories': 410, 'stock': 25,
        'category': 'fastfood', 'imageUrl': 'assets/images/hot_dog.jpg',
        'nutrients': {'protein': 16.0, 'carbs': 42.0, 'fat': 20.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy'],
      },
      {
        'name': 'Pizza Dilimi',
        'description': 'Peynirli veya karışık pizza dilimi.',
        'price': 80.0, 'calories': 300, 'stock': 30,
        'category': 'fastfood', 'imageUrl': 'assets/images/pizza_dilimi.jpg',
        'nutrients': {'protein': 14.0, 'carbs': 38.0, 'fat': 11.0, 'fiber': 2.0},
        'allergens': ['gluten', 'dairy'],
      },
      {
        'name': 'Wrap Sandviç',
        'description': 'Tavuk, marul, domates ve ranch soslu dürüm wrap.',
        'price': 110.0, 'calories': 420, 'stock': 20,
        'category': 'fastfood', 'imageUrl': 'assets/images/wrap_sandvic.jpg',
        'nutrients': {'protein': 24.0, 'carbs': 44.0, 'fat': 14.0, 'fiber': 3.0},
        'allergens': ['gluten', 'dairy'],
      },

      // ── DİYET (DIET) ──────────────────────────────────────────────
      {
        'name': 'Quinoa Salad',
        'nameTr': 'Kinoa Salatası',
        'description': 'Nutritious quinoa with fresh vegetables and lemon dressing.',
        'descriptionTr': 'Taze sebzeler ve limon soslu besleyici kinoa.',
        'price': 135.0, 'calories': 220, 'stock': 20,
        'category': 'diet', 'imageUrl': 'assets/images/quinoa_bowl.jpg',
        'nutrients': {'protein': 12.0, 'carbs': 35.0, 'fat': 6.0, 'fiber': 8.0},
        'allergens': [],
        'isVegan': true,
        'isGlutenFree': true,
      },
      {
        'name': 'Grilled Salmon',
        'nameTr': 'Izgara Somon',
        'description': 'Omega-3 rich grilled salmon with steamed broccoli.',
        'descriptionTr': 'Buharda pişmiş brokoli ile omega-3 zengini ızgara somon.',
        'price': 285.0, 'calories': 310, 'stock': 15,
        'category': 'diet', 'imageUrl': 'assets/images/balik_tava.jpg',
        'nutrients': {'protein': 32.0, 'carbs': 5.0, 'fat': 18.0, 'fiber': 2.0},
        'allergens': ['fish'],
        'isVegan': false,
        'isGlutenFree': true,
      },
      {
        'name': 'Green Smoothie',
        'nameTr': 'Yeşil Smoothie',
        'description': 'Detox drink with spinach, apple, and ginger.',
        'descriptionTr': 'Ispanak, elma ve zencefil ile detoks içeceği.',
        'price': 75.0, 'calories': 120, 'stock': 40,
        'category': 'diet', 'imageUrl': 'assets/images/water.jpg',
        'nutrients': {'protein': 3.0, 'carbs': 25.0, 'fat': 1.0, 'fiber': 5.0},
        'allergens': [],
        'isVegan': true,
        'isGlutenFree': true,
      },
      {
        'name': 'Chia Pudding',
        'nameTr': 'Chia Puding',
        'description': 'Sugar-free chia pudding with almond milk and berries.',
        'descriptionTr': 'Badem sütü ve orman meyveli şekersiz chia puding.',
        'price': 85.0, 'calories': 180, 'stock': 25,
        'category': 'diet', 'imageUrl': 'assets/images/rice_pudding.jpg',
        'nutrients': {'protein': 6.0, 'carbs': 22.0, 'fat': 8.0, 'fiber': 10.0},
        'allergens': ['nuts'],
        'isVegan': true,
        'isGlutenFree': true,
      },
    ];
  }

  static Future<void> _seedTodayMenu() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      // Check if menu exists
      final menuSnap = await _db.collection('menus')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayStart.add(const Duration(days: 1))))
          .get();

      if (menuSnap.docs.isEmpty) {
        // Get some meal IDs
        final mealsSnap = await _db.collection('meals').limit(6).get();
        final ids = mealsSnap.docs.map((d) => d.id).toList();
        
        if (ids.isNotEmpty) {
          await _db.collection('menus').add({
            'date': Timestamp.fromDate(todayStart),
            'mealIds': ids,
            'cafeteriaId': 'main',
          });
          debugPrint('📝 Günlük menü oluşturuldu.');
        }
      }
    } catch (e) {
      debugPrint('❌ Menu seed hatası: $e');
    }
  }
}
