import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/meal.dart';
import 'menu_service.dart';
import 'cart_service.dart';
import 'language_service.dart';

enum BotState {
  idle,
  waitingForCategory,
  waitingForDiet,
  waitingForCalories,
}

class ChatbotService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  BotState _state = BotState.idle;
  
  // States for the recommendation flow
  String? _selectedCategory;
  String? _selectedDiet;
  int? _selectedCalorieLimit;

  List<ChatMessage> get messages => _messages;
  BotState get state => _state;

  ChatbotService() {
    // Initial welcome message will be populated dynamically based on language
  }

  void addWelcomeMessage(LanguageService lang) {
    if (_messages.isNotEmpty) return;
    _messages.add(
      ChatMessage(
        text: lang.isTurkish
            ? 'Merhaba! Ben IKAS Fis Akıllı Asistanıyım. 🤖 Yemeklerimiz, kalorileri veya siparişiniz hakkında size yardımcı olabilirim.\n\nNasıl yardımcı olayım?'
            : 'Hello! I am the IKAS Fis Smart Assistant. 🤖 I can help you with our meals, their calories, or your order.\n\nHow can I help you?',
        isBot: true,
        quickReplies: _getInitialReplies(lang),
      ),
    );
    notifyListeners();
  }

  void clearChat(LanguageService lang) {
    _messages.clear();
    _state = BotState.idle;
    _selectedCategory = null;
    _selectedDiet = null;
    _selectedCalorieLimit = null;
    addWelcomeMessage(lang);
  }

  List<String> _getInitialReplies(LanguageService lang) {
    return lang.isTurkish
        ? [
            '📋 Ürünler',
            '🤔 Bugün ne yesem?',
            '🥗 Diyet Önerileri',
            '🛒 Sepetim ne kadar?',
            '⏰ Yemekhane Bilgisi',
          ]
        : [
            '📋 Products',
            '🤔 What to eat?',
            '🥗 Diet Suggestions',
            '🛒 How much is my cart?',
            '⏰ Cafeteria Info',
          ];
  }

  String _normalize(String text) {
    return text.toLowerCase()
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o');
  }

  bool _isGibberish(String text) {
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (clean.isEmpty) {
      return false;
    }
    
    // Check if it has no vowels (in both TR and EN normalizations)
    final vowels = RegExp(r'[aeiouıöüâêîûoö]');
    if (!clean.contains(vowels)) {
      return true; // No vowels, e.g., "sdfsdf", "qwrqwr", "hjkhkh"
    }

    // Repeated identical character sequences
    if (clean.length > 4) {
      for (int i = 0; i < clean.length - 3; i++) {
        final char = clean[i];
        if (clean[i + 1] == char && clean[i + 2] == char && clean[i + 3] == char) {
          return true; // 4 consecutive same chars, e.g. "aaaa", "xxxx"
        }
      }
    }

    return false;
  }

  bool _isLikelyProductQuery(String text) {
    final clean = _normalize(text.toLowerCase().trim());
    if (clean.isEmpty) return false;

    // Gibberish is not a product query
    if (_isGibberish(clean)) return false;

    // Check for only numbers/special characters
    final onlySpecial = RegExp(r'^[^a-z]+$');
    if (onlySpecial.hasMatch(clean)) return false;

    // Explicit food search structure checks
    final foodSearchPhrasals = {
      'var mi', 'bulunur mu', 'do you have', 'is there', 'kalori', 'calor', 'fiyat', 'price', 
      'stok', 'stock', 'menude', 'menu de', 'satin al', 'buy', 'ekle', 'add', 'porsiyon', 
      'portion', 'gram', 'kcal', 'tutar', 'cost', 'siparis', 'order', 'yemekler', 'products',
      'urunler', 'listesi', 'list', 'taze', 'fresh', 'sicak', 'hot', 'soguk', 'cold', 'tatli',
      'sweet', 'tuzlu', 'salty', 'baharatli', 'spicy', 'acili', 'aci', 'eksi', 'sour'
    };

    // If it contains any explicit food search phrases/words
    for (var phrase in foodSearchPhrasals) {
      if (clean.contains(phrase)) return true;
    }

    // Explicit keywords indicating a search for a product/food item
    final foodKeywords = {
      'yemek', 'menu', 'corba', 'soup', 'tavuk', 'chicken', 'kofte', 'meatball', 'manti', 'lahmacun', 
      'salata', 'salad', 'sutlac', 'pudding', 'ayran', 'su', 'water', 'sebze', 'vegetable', 'kinoa', 
      'quinoa', 'somon', 'salmon', 'pilav', 'rice', 'makarna', 'pasta', 'et', 'meat', 'balik', 
      'fish', 'tatli', 'dessert', 'icecek', 'drink', 'burger', 'pizza', 'pide', 'doner', 'kebap', 
      'meyve', 'fruit', 'ekmek', 'bread', 'peynir', 'cheese', 'sut', 'milk', 'yogurt', 'cacik', 
      'patates', 'potato', 'sos', 'sauce', 'cay', 'tea', 'kahve', 'coffee', 'kola', 'soda', 
      'meyve suyu', 'juice', 'helva', 'baklava', 'borek', 'fasulye', 'nohut', 'mercimek', 
      'bulgur', 'tost', 'sandvic', 'sandwich', 'wrap', 'durum', 'kavurma', 'kuzu', 'dana', 
      'tavuklu', 'etli', 'peynirli', 'sebzeli', 'sosis', 'sucuk', 'salam', 'kraker', 'cikolata', 
      'chocolate', 'biskuvi', 'biscuit', 'cips', 'chips', 'kurabiye', 'cookie', 'kek', 'cake', 
      'dondurma', 'ice cream', 'waffle', 'krep', 'pancake', 'acma', 'pogaca', 'simit', 'noodle', 
      'humus', 'falafel', 'tacos', 'taco', 'burrito', 'sushi', 'ramen', 'steak', 'bonfile', 
      'pirzola', 'antrikot', 'guvec', 'sote', 'ezme', 'haydari', 'pilaki', 'meze', 'bira', 
      'beer', 'sarap', 'wine', 'viski', 'whiskey', 'raki', 'biber', 'domates', 'patlican', 
      'kabak', 'havuc', 'sogan', 'sarimsak', 'ispanak', 'pazi', 'lahana', 'karnabahar', 
      'brokoli', 'enginar', 'kereviz', 'pirasa', 'bamya', 'barbunya', 'bezelye', 'misir', 
      'corn', 'tuz', 'seker', 'un', 'yag', 'tereyagi', 'zeytinyagi', 'yumurta', 'egg', 'bal', 
      'honey', 'recel', 'jam', 'kaymak', 'cream', 'pekmez', 'tahin', 'fistik', 'findik', 
      'badem', 'ceviz', 'kaju', 'leblebi', 'elma', 'apple', 'armut', 'pear', 'muz', 'banana',
      'cilek', 'strawberry', 'kiraz', 'cherry', 'visne', 'erik', 'seftali', 'peach', 
      'kayisi', 'apricot', 'uzum', 'grape', 'incir', 'fig', 'nar', 'pomegranate', 'kavun',
      'melon', 'karpuz', 'watermelon', 'portakal', 'orange', 'mandalina', 'mandarin', 
      'limon', 'lemon', 'greyfurt', 'kivi', 'kiwi', 'ananas', 'pineapple', 'avokado', 
      'avocado', 'coconut', 'blueberry', 'bogurtlen', 'ahududu', 'date', 'almond', 
      'hazelnut', 'walnut', 'pistachio', 'ice'
    };

    // Split text into words and check if any word matches common food keywords
    final words = clean.split(RegExp(r'[^a-z0-9]+'));
    for (var word in words) {
      if (word.length >= 2) {
        final matchesFoodKeyword = foodKeywords.any((keyword) => 
          word == keyword || 
          (word.length >= 4 && keyword.contains(word)) || 
          (keyword.length >= 4 && word.contains(keyword))
        );
        if (matchesFoodKeyword) {
          return true;
        }
      } else if (word == 'su' || word == 'et') {
        return true;
      }
    }

    return false;
  }

  int _getLevenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v0[t.length];
  }

  int _min3(int a, int b, int c) {
    int min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }

  bool _isGlobalCommand(String text) {
    final cleanText = text.toLowerCase().trim();
    // Strip emojis and punctuation for command checking
    final norm = cleanText
        .replaceAll(RegExp(r'[?.,\/#!$%\^&\*;:{}=\-_`~()\"’]|[📋🤔🥗🛒⏰❌🌱🌾🔥⚡♾️]'), '')
        .trim();
    
    // Explicit list of normalized global command strings
    final globalCommands = {
      'urunler', 'products', 'menu', 'menü',
      'bugun ne yesem', 'bugün ne yesem', 'what to eat', 'what should i eat',
      'diyet onerileri', 'diyet önerileri', 'diet suggestions', 'diet suggestion',
      'sepetim ne kadar', 'how much is my cart', 'sepet', 'sepetim', 'cart',
      'yemekhane bilgisi', 'cafeteria info', 'yemekhane', 'cafeteria',
      'yardim', 'yardım', 'help', 'destek', 'support',
      'iptal', 'vazgec', 'vazgeç', 'cancel', 'exit', 'stop',
      'merhaba', 'selam', 'hello', 'hi', 'hey',
      'kimsin', 'who are you'
    };

    if (globalCommands.contains(norm)) {
      return true;
    }

    // Also check substring/contains for very common ones
    if (norm.contains('sepet') || 
        norm.contains('cart') ||
        norm.contains('yemekhane') ||
        norm.contains('cafeteria') ||
        norm.contains('yardim') ||
        norm.contains('yardım') ||
        norm.contains('help') ||
        norm.contains('kimsin') ||
        norm.contains('who are you') ||
        norm.contains('diyet önerileri') ||
        norm.contains('diet suggestions') ||
        norm.contains('bugün ne yesem') ||
        norm.contains('what to eat')) {
      return true;
    }

    return false;
  }

  // Main input handler
  void sendMessage(String text, LanguageService lang, MenuService menuService, CartService cartService) {
    if (text.trim().isEmpty) return;

    // 1. Add user message
    _messages.add(ChatMessage(text: text, isBot: false));
    notifyListeners();

    final cleanText = text.toLowerCase().trim();
    final isCancel = cleanText == 'iptal' || 
                     cleanText == 'vazgec' || 
                     cleanText == 'cancel' || 
                     cleanText == 'exit' || 
                     cleanText == 'stop' || 
                     cleanText == 'abort' ||
                     cleanText.contains('iptal') ||
                     cleanText.contains('vazgec') ||
                     cleanText.contains('vazgeç') ||
                     cleanText.contains('cancel');

    if (isCancel) {
      _state = BotState.idle;
      _selectedCategory = null;
      _selectedDiet = null;
      _selectedCalorieLimit = null;
      Future.delayed(const Duration(milliseconds: 600), () {
        _messages.add(
          ChatMessage(
            text: lang.isTurkish
                ? 'Öneri akışını iptal ettim. Başka nasıl yardımcı olabilirim? 🌸'
                : 'I have canceled the recommendation flow. How else can I help you? 🌸',
            isBot: true,
            quickReplies: _getInitialReplies(lang),
          ),
        );
        notifyListeners();
      });
      return;
    }

    final isGlobalKeyword = _isGlobalCommand(text);

    if (isGlobalKeyword && _state != BotState.idle) {
      // User typed a global command while in state flow, reset state flow
      _state = BotState.idle;
      _selectedCategory = null;
      _selectedDiet = null;
      _selectedCalorieLimit = null;
    }

    // 2. Process via rule engine or state machine
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_state != BotState.idle) {
        _handleStateFlow(text, lang, menuService, cartService);
      } else {
        _handleKeywordRules(text, lang, menuService, cartService);
      }
      notifyListeners();
    });
  }

  // Handle step-by-step recommendation flow
  void _handleStateFlow(String text, LanguageService lang, MenuService menuService, CartService cartService) {
    final cleanText = text.toLowerCase().trim();
    final isTr = lang.isTurkish;

    switch (_state) {
      case BotState.waitingForCategory:
        final normText = _normalize(cleanText);
        // Parse Category
        if (normText.contains('main') || normText.contains('ana') || normText.contains('1')) {
          _selectedCategory = 'main';
        } else if (normText.contains('soup') || normText.contains('corba') || normText.contains('2')) {
          _selectedCategory = 'soup';
        } else if (normText.contains('salad') || normText.contains('salata') || normText.contains('3')) {
          _selectedCategory = 'salad';
        } else if (normText.contains('dessert') || normText.contains('tatli') || normText.contains('4')) {
          _selectedCategory = 'dessert';
        } else if (normText.contains('drink') || normText.contains('icecek') || normText.contains('5')) {
          _selectedCategory = 'drink';
        } else {
          _selectedCategory = 'any';
        }

        _state = BotState.waitingForDiet;
        _messages.add(
          ChatMessage(
            text: isTr
                ? 'Harika! Peki herhangi bir diyet kısıtlamanız var mı?'
                : 'Great! Do you have any dietary restrictions?',
            isBot: true,
            quickReplies: isTr
                ? ['🌱 Vegan', '🌾 Glütensiz', '❌ Kısıtlama Yok', '❌ İptal']
                : ['🌱 Vegan', '🌾 Gluten-Free', '❌ No restriction', '❌ Cancel'],
          ),
        );
        break;

      case BotState.waitingForDiet:
        final normText = _normalize(cleanText);
        if (normText.contains('vegan')) {
          _selectedDiet = 'vegan';
        } else if (normText.contains('glut') || normText.contains('glüt')) {
          _selectedDiet = 'gluten_free';
        } else {
          _selectedDiet = 'none';
        }

        _state = BotState.waitingForCalories;
        _messages.add(
          ChatMessage(
            text: isTr
                ? 'Son olarak, kalori limiti belirlemek ister misiniz?'
                : 'Finally, would you like to set a calorie limit?',
            isBot: true,
            quickReplies: isTr
                ? ['🔥 < 300 kcal', '⚡ < 500 kcal', '♾️ Limit Yok', '❌ İptal']
                : ['🔥 < 300 kcal', '⚡ < 500 kcal', '♾️ No limit', '❌ Cancel'],
          ),
        );
        break;

      case BotState.waitingForCalories:
        if (cleanText.contains('300')) {
          _selectedCalorieLimit = 300;
        } else if (cleanText.contains('500')) {
          _selectedCalorieLimit = 500;
        } else {
          _selectedCalorieLimit = 99999;
        }

        _executeRecommendation(lang, menuService);
        break;

      default:
        _state = BotState.idle;
        break;
    }
  }

  void _executeRecommendation(LanguageService lang, MenuService menuService) {
    final isTr = lang.isTurkish;
    final meals = menuService.meals;

    // Filter meals
    final filtered = meals.where((meal) {
      // 1. Category
      if (_selectedCategory != null && _selectedCategory != 'any') {
        if (meal.category != _selectedCategory) return false;
      }
      // 2. Diet
      if (_selectedDiet == 'vegan' && !meal.isVegan) return false;
      if (_selectedDiet == 'gluten_free' && !meal.isGlutenFree) return false;
      // 3. Calories
      if (_selectedCalorieLimit != null && meal.calories > _selectedCalorieLimit!) return false;

      // 4. Stock check
      if (!meal.isAvailable) return false;

      return true;
    }).toList();

    _state = BotState.idle;

    if (filtered.isEmpty) {
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Aradığınız kriterlere uygun güncel bir yemek bulamadım. 😔 Farklı kriterlerle tekrar deneyebilir veya tüm menümüzü inceleyebilirsiniz.'
              : 'I could not find any active meal matching your criteria. 😔 You can try again with different criteria or check our full menu.',
          isBot: true,
          quickReplies: _getInitialReplies(lang),
        ),
      );
    } else {
      // Pick top 3 results
      final recommendations = filtered.take(3).toList();
      
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'İşte kriterlerinize göre seçtiğim lezzetli seçenekler: ✨'
              : 'Here are the delicious options I selected for you: ✨',
          isBot: true,
        ),
      );

      for (var meal in recommendations) {
        final name = meal.getLocalizedName(isTr);
        final desc = meal.getLocalizedDescription(isTr);
        final buffer = StringBuffer();
        buffer.writeln('🍴 **$name** (${meal.price.toStringAsFixed(2)} ₺)');
        buffer.writeln('🔥 ${meal.calories} kcal | 🥩 P: ${meal.nutrients['protein'] ?? 0}g, C: ${meal.nutrients['carbs'] ?? 0}g');
        if (meal.isVegan) buffer.write('🌱 Vegan ');
        if (meal.isGlutenFree) buffer.write(isTr ? '🌾 Glütensiz' : '🌾 Gluten-Free');
        buffer.writeln('\n\n_${desc}_');

        _messages.add(
          ChatMessage(
            text: buffer.toString(),
            isBot: true,
            actionType: 'add_to_cart',
            actionData: meal.id,
          ),
        );
      }

      // Add a follow up bubble with the initial quick replies so the user can easily perform another action
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Başka bir işlem yapmak ister misiniz?'
              : 'Would you like to do anything else?',
          isBot: true,
          quickReplies: _getInitialReplies(lang),
        ),
      );
    }
  }

  // Handle standard text based expert rules
  void _handleKeywordRules(String text, LanguageService lang, MenuService menuService, CartService cartService) {
    final cleanText = text.toLowerCase().trim();
    final isTr = lang.isTurkish;
    final selectedStockInStock = isTr ? 'Stokta var' : 'In stock';
    final selectedStockOutOfStock = isTr ? 'Stokta yok' : 'Out of stock';

    // 1. Intent: Recommendation / Undecided
    if (cleanText.contains('ne yesem') ||
        cleanText.contains('kararsız') ||
        cleanText.contains('öner') ||
        cleanText.contains('yiyebilirim') ||
        cleanText.contains('what should i eat') ||
        cleanText.contains('what to eat') ||
        cleanText.contains('recommend') ||
        cleanText.contains('undecided')) {
      _state = BotState.waitingForCategory;
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Harika! Sizi lezzetli bir yemeğe yönlendireyim. 🍽️ Öncelikle hangi kategoriyle başlayalım?'
              : 'Great! Let me guide you to a delicious meal. 🍽️ Which category shall we start with?',
          isBot: true,
          quickReplies: isTr
              ? ['🍖 Ana Yemek', '🥣 Çorba', '🥗 Salata', '🍰 Tatlı', '🥤 İçecek', '✨ Fark Etmez', '❌ İptal']
              : ['🍖 Main Dish', '🥣 Soup', '🥗 Salad', '🍰 Dessert', '🥤 Drink', '✨ Any', '❌ Cancel'],
        ),
      );
      return;
    }

    // 2. Intent: Product Information / Menu List
    if (cleanText.contains('ürünler hakkında bilgi') ||
        cleanText.contains('product information') ||
        cleanText.contains('ürünler') ||
        cleanText.contains('products') ||
        cleanText.contains('menü') ||
        cleanText.contains('menu') ||
        cleanText.contains('yemekler') ||
        cleanText.contains('listesi') ||
        cleanText.contains('list')) {
      
      final activeMeals = menuService.meals.where((m) => m.isAvailable).toList();
      if (activeMeals.isEmpty) {
        _messages.add(
          ChatMessage(
            text: isTr
                ? 'Şu anda menümüzde aktif veya stokta olan bir ürün bulunamadı. 😔'
                : 'No active or in-stock products found on the menu right now. 😔',
            isBot: true,
            quickReplies: _getInitialReplies(lang),
          ),
        );
      } else {
        final buffer = StringBuffer();
        buffer.writeln(isTr
            ? '📋 **Menümüzdeki Aktif Ürünler:**\nDetayını öğrenmek istediğiniz yemeğin adına tıklayabilir veya ismini yazabilirsiniz! 🍴\n'
            : '📋 **Active Menu Items:**\nClick on any product chip below or type its name to view details! 🍴\n');
        
        for (var m in activeMeals) {
          buffer.writeln('• **${m.getLocalizedName(isTr)}** - ${m.price.toStringAsFixed(2)} ₺ (${m.calories} kcal)');
        }

        // Generate top product names as quick replies for instant clicking!
        final productChips = activeMeals.take(4).map((m) => m.getLocalizedName(isTr)).toList();

        _messages.add(
          ChatMessage(
            text: buffer.toString(),
            isBot: true,
            quickReplies: productChips.isNotEmpty ? productChips : _getInitialReplies(lang),
          ),
        );
      }
      return;
    }

    // 3. Intent: Cafeteria / Market Info
    if (cleanText.contains('yemekhane') ||
        cleanText.contains('market') ||
        cleanText.contains('cafeteria') ||
        cleanText.contains('saat') ||
        cleanText.contains('zaman') ||
        cleanText.contains('açık') ||
        cleanText.contains('open') ||
        cleanText.contains('hour') ||
        cleanText.contains('time') ||
        cleanText.contains('work') ||
        cleanText.contains('ödeme') ||
        cleanText.contains('pay') ||
        cleanText.contains('para') ||
        cleanText.contains('kart') ||
        cleanText.contains('nakit')) {
      _messages.add(
        ChatMessage(
          text: isTr
              ? '⏰ **Yemekhane Çalışma Saatleri:**\n'
                  'Hafta içi her gün **08:30 - 18:30** saatleri arasında açığız. Hafta sonları kapalıyız.\n\n'
                  '💳 **Ödeme Bilgisi:**\n'
                  'Uygulama üzerinden ödeme alınmamaktadır. Siparişinizi oluşturduktan sonra yemekhane kasasında nakit veya kart ile ödeme yapabilirsiniz.'
              : '⏰ **Cafeteria Operating Hours:**\n'
                  'We are open weekdays from **08:30 to 18:30**. We are closed on weekends.\n\n'
                  '💳 **Payment Information:**\n'
                  'We do not collect online payments. You can pay with cash or credit card at the register upon pickup.',
          quickReplies: _getInitialReplies(lang),
          isBot: true,
        ),
      );
      return;
    }

    // 4. Intent: Cart Status Check
    if (cleanText.contains('sepet') || cleanText.contains('cart') || cleanText.contains('tutar') || cleanText.contains('hesap')) {
      final count = cartService.itemCount;
      final total = cartService.totalPrice;
      if (count == 0) {
        _messages.add(
          ChatMessage(
            text: isTr
                ? 'Sepetiniz şu anda boş. 🛒 Menümüzden lezzetli yemekler ekleyebilirsiniz!'
                : 'Your cart is currently empty. 🛒 Feel free to add some delicious food from our menu!',
            quickReplies: _getInitialReplies(lang),
            isBot: true,
          ),
        );
      } else {
        _messages.add(
          ChatMessage(
            text: isTr
                ? 'Sepetinizde **$count** ürün bulunuyor. 🛒\nToplam Tutar: **${total.toStringAsFixed(2)} ₺**'
                : 'You have **$count** items in your cart. 🛒\nTotal Price: **${total.toStringAsFixed(2)} ₺**',
            quickReplies: _getInitialReplies(lang),
            isBot: true,
          ),
        );
      }
      return;
    }

    // 5. Intent: Diet / Healthy Options
    if (cleanText.contains('diyet') ||
        cleanText.contains('sağlık') ||
        cleanText.contains('diet') ||
        cleanText.contains('healthy') ||
        cleanText.contains('vegan') ||
        cleanText.contains('gluten') ||
        cleanText.contains('glüt')) {
      final healthyMeals = menuService.meals.where((m) => (m.calories < 400 || m.isVegan || m.isGlutenFree) && m.isAvailable).toList();
      if (healthyMeals.isEmpty) {
        _messages.add(
          ChatMessage(
            text: isTr
                ? 'Şu anda sistemde diyet veya sağlıklı seçenek bulunamadı. 🍏'
                : 'No diet or healthy food options found in the system right now. 🍏',
            isBot: true,
            quickReplies: _getInitialReplies(lang),
          ),
        );
      } else {
        final buffer = StringBuffer();
        buffer.writeln(isTr
            ? '🍏 **Diyet & Sağlıklı Yemek Önerilerimiz:**\n'
            : '🍏 **Diet & Healthy Meal Suggestions:**\n');
        
        for (var m in healthyMeals.take(3)) {
          final name = m.getLocalizedName(isTr);
          buffer.writeln('• **$name** (${m.calories} kcal) - ${m.price.toStringAsFixed(2)} ₺');
          if (m.isVegan) buffer.write('  🌱 Vegan ');
          if (m.isGlutenFree) buffer.write(isTr ? '  🌾 Glütensiz' : '  🌾 Gluten-Free');
          buffer.writeln();
        }
        
        _messages.add(
          ChatMessage(
            text: buffer.toString(),
            isBot: true,
            quickReplies: _getInitialReplies(lang),
          ),
        );
      }
      return;
    }

    // 6. Intent: Specific Product Details Search (checks dynamic food names with priority)
    final normQuery = _normalize(cleanText)
        .replaceAll(RegExp(r'[?.,\/#!$%\^&\*;:{}=\-_`~()\"’]|[📋🤔🥗🛒⏰❌🌱🌾🔥⚡♾️]'), '')
        .trim();

    // Group 1: Normalized exact name match
    final exactMatches = menuService.meals.where((meal) {
      final n = _normalize(meal.getLocalizedName(isTr));
      final nEn = _normalize(meal.name);
      final nTr = _normalize(meal.nameTr);
      return n == normQuery || nEn == normQuery || nTr == normQuery;
    }).toList();

    // Group 2: Whole word matches
    final wordMatches = menuService.meals.where((meal) {
      final nWords = _normalize(meal.getLocalizedName(isTr)).split(RegExp(r'\s+'));
      final nEnWords = _normalize(meal.name).split(RegExp(r'\s+'));
      final nTrWords = _normalize(meal.nameTr).split(RegExp(r'\s+'));
      return nWords.contains(normQuery) || nEnWords.contains(normQuery) || nTrWords.contains(normQuery);
    }).toList();

    // Group 3: Word prefix matches
    final prefixMatches = menuService.meals.where((meal) {
      final nWords = _normalize(meal.getLocalizedName(isTr)).split(RegExp(r'\s+'));
      final nEnWords = _normalize(meal.name).split(RegExp(r'\s+'));
      final nTrWords = _normalize(meal.nameTr).split(RegExp(r'\s+'));
      return nWords.any((w) => w.startsWith(normQuery)) ||
             nEnWords.any((w) => w.startsWith(normQuery)) ||
             nTrWords.any((w) => w.startsWith(normQuery));
    }).toList();

    // Group 4: Substring matches (only for queries length >= 3 to avoid single char noise)
    final substringMatches = menuService.meals.where((meal) {
      final n = _normalize(meal.getLocalizedName(isTr));
      final nEn = _normalize(meal.name);
      final nTr = _normalize(meal.nameTr);
      return n.contains(normQuery) || nEn.contains(normQuery) || nTr.contains(normQuery);
    }).toList();

    Meal? bestMatch;
    bool isFuzzy = false;

    if (exactMatches.isNotEmpty) {
      bestMatch = exactMatches.first;
    } else if (wordMatches.isNotEmpty) {
      bestMatch = wordMatches.first;
    } else if (prefixMatches.isNotEmpty) {
      bestMatch = prefixMatches.first;
    } else if (substringMatches.isNotEmpty && normQuery.length >= 3) {
      bestMatch = substringMatches.first;
    } else {
      // Group 5: Fuzzy Levenshtein Match (limit to 1 or 2 distance depending on length)
      final fuzzyMeals = menuService.meals.where((meal) {
        final n = _normalize(meal.getLocalizedName(isTr));
        final nEn = _normalize(meal.name);
        final nTr = _normalize(meal.nameTr);
        
        final limit = normQuery.length >= 5 ? 2 : 1;
        return _getLevenshteinDistance(normQuery, n) <= limit ||
               _getLevenshteinDistance(normQuery, nEn) <= limit ||
               _getLevenshteinDistance(normQuery, nTr) <= limit;
      }).toList();

      if (fuzzyMeals.isNotEmpty) {
        bestMatch = fuzzyMeals.first;
        isFuzzy = true;
      }
    }

    if (bestMatch != null) {
      final name = bestMatch.getLocalizedName(isTr);
      final desc = bestMatch.getLocalizedDescription(isTr);
      
      final header = isFuzzy
          ? (isTr 
              ? '🤔 Sanırım **$name** yemeğini arıyordunuz. İşte detaylar:\n\n'
              : '🤔 I think you were looking for **$name**. Here are the details:\n\n')
          : (isTr 
              ? '🔍 **$name** hakkında bulduğum detaylar:\n\n'
              : '🔍 Details I found for **$name**:\n\n');

      final reply = header + (isTr
          ? '💵 **Fiyat:** ${bestMatch.price.toStringAsFixed(2)} ₺\n'
              '🔥 **Kalori:** ${bestMatch.calories} kcal\n'
              '🥩 **Besin Değerleri:** Protein: ${bestMatch.nutrients['protein'] ?? 0}g, Karb: ${bestMatch.nutrients['carbs'] ?? 0}g, Yağ: ${bestMatch.nutrients['fat'] ?? 0}g\n'
              '🌾 **Glütensiz:** ${bestMatch.isGlutenFree ? 'Evet' : 'Hayır'}\n'
              '🌱 **Vegan:** ${bestMatch.isVegan ? 'Evet' : 'Hayır'}\n\n'
              '_${desc}_'
          : '💵 **Price:** ${bestMatch.price.toStringAsFixed(2)} ₺\n'
              '🔥 **Calories:** ${bestMatch.calories} kcal\n'
              '🥩 **Nutrients:** Protein: ${bestMatch.nutrients['protein'] ?? 0}g, Carbs: ${bestMatch.nutrients['carbs'] ?? 0}g, Fat: ${bestMatch.nutrients['fat'] ?? 0}g\n'
              '🌾 **Gluten-Free:** ${bestMatch.isGlutenFree ? 'Yes' : 'No'}\n'
              '🌱 **Vegan:** ${bestMatch.isVegan ? 'Yes' : 'No'}\n\n'
              '_${desc}_');

      _messages.add(
        ChatMessage(
          text: reply,
          isBot: true,
          quickReplies: _getInitialReplies(lang),
          actionType: bestMatch.isAvailable ? 'add_to_cart' : null,
          actionData: bestMatch.id,
        ),
      );
      return;
    }

    // 7. Intent: Gratitude / Thanks
    if (cleanText.contains('teşekkür') ||
        cleanText.contains('tesekkur') ||
        cleanText.contains('sagol') ||
        cleanText.contains('sağol') ||
        cleanText.contains('thanks') ||
        cleanText.contains('thank you') ||
        cleanText.contains('merci')) {
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Rica ederim! 😊 Yardımcı olabildiysem ne mutlu. Afiyet olsun!'
              : 'You\'re welcome! 😊 Glad I could help. Enjoy your meal!',
          isBot: true,
          quickReplies: _getInitialReplies(lang),
        ),
      );
      return;
    }

    // 8. Intent: Allergens general query
    if (cleanText.contains('alerjen') || cleanText.contains('allergen')) {
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Yemeklerimizin alerjen detaylarını öğrenmek için yemek adını yazmanız yeterlidir. Örneğin: **"Anne Köftesi"** veya **"Grilled Chicken"**. İlgili detay kartında glüten, süt ürünleri vb. alerjen bilgileri listelenecektir.'
              : 'To check the allergen details of any dish, simply type the name of the dish. For example: **"Meatballs"** or **"Grilled Chicken"**. The card will show if it contains gluten, dairy, or other allergens.',
          isBot: true,
          quickReplies: _getInitialReplies(lang),
        ),
      );
      return;
    }

    // 9. Greeting / Merhaba
    if (cleanText.contains('merhaba') ||
        cleanText.contains('selam') ||
        cleanText.contains('hey') ||
        cleanText.contains('hello') ||
        cleanText.contains('hi')) {
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Tekrar merhaba! Size nasıl yardımcı olabilirim? 🌸'
              : 'Hello again! How can I help you today? 🌸',
          isBot: true,
          quickReplies: _getInitialReplies(lang),
        ),
      );
      return;
    }

    // 10. Intent: Bot Identity / Who are you
    if (cleanText.contains('kimsin') ||
        cleanText.contains('nesin') ||
        cleanText.contains('adın ne') ||
        cleanText.contains('adin ne') ||
        cleanText.contains('adiniz ne') ||
        cleanText.contains('who are you') ||
        cleanText.contains('what is your name') ||
        cleanText.contains('what are you')) {
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Ben IKAS Fis Akıllı Asistanıyım! 🤖 Yemekhane menüsü, yemeklerin kalori/besin değerleri ve sipariş durumunuz hakkında size yardımcı olmak için tasarlanmış bir yapay zeka yardımcısıyım. Nasıl yardımcı olabilirim?'
              : 'I am the IKAS Fis Smart Assistant! 🤖 I am an AI assistant designed to help you with the cafeteria menu, food calories/nutrients, and your order status. How can I help you?',
          isBot: true,
          quickReplies: _getInitialReplies(lang),
        ),
      );
      return;
    }

    // 11. Intent: Help / How to use
    if (cleanText.contains('yardım') ||
        cleanText.contains('yardim') ||
        cleanText.contains('help') ||
        cleanText.contains('destek') ||
        cleanText.contains('support') ||
        cleanText.contains('nasıl kullanılır') ||
        cleanText.contains('nasil kullanilir') ||
        cleanText.contains('how to use')) {
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Size şu konularda yardımcı olabilirim: 🌸\n\n'
                  '• **📋 Ürünler:** Menümüzdeki güncel yemekleri listelemek için\n'
                  '• **🤔 Bugün ne yesem?:** Kriterlerinize göre yemek önerisi almak için\n'
                  '• **🥗 Diyet:** Vegan veya glütensiz seçenekleri görmek için\n'
                  '• **⏰ Yemekhane Bilgisi:** Çalışma saatleri ve ödeme yöntemlerini öğrenmek için\n'
                  '• **🛒 Sepetim:** Sepetinizdeki ürün sayısını ve toplam tutarı görmek için\n'
                  '• **🔍 Arama:** Doğrudan bir yemeğin adını yazarak detaylı kalori ve besin değerlerini öğrenebilirsiniz (Örn: \'Su\', \'Izgara Tavuk\').'
              : 'I can help you with the following: 🌸\n\n'
                  '• **📋 Products:** To list the current meals on our menu\n'
                  '• **🤔 What to eat?:** To get recommendations based on your preferences\n'
                  '• **🥗 Diet Suggestions:** To view vegan or gluten-free options\n'
                  '• **⏰ Cafeteria Info:** To learn about hours and payment methods\n'
                  '• **🛒 My Cart:** To check your cart items and total amount\n'
                  '• **🔍 Search:** Type the name of any dish to see calories and nutrients (e.g., \'Water\', \'Grilled Chicken\').',
          isBot: true,
          quickReplies: _getInitialReplies(lang),
        ),
      );
      return;
    }

    // 12. Dynamic Fallback: Check if it looks like a missing product query
    final isProductQuery = _isLikelyProductQuery(cleanText);

    if (isProductQuery) {
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Aradığınız **\'$text\'** ürünü menümüzde bulunmamaktadır. 😔 Diğer yemeklerimize göz atmak için **\'Ürünler\'** yazabilir veya başka bir yemek arayabilirsiniz.'
              : 'The product **\'$text\'** is not available in our menu. 😔 You can type **\'Products\'** to see other items or search for another meal.',
          isBot: true,
          quickReplies: [
            isTr ? '📋 Ürünler' : '📋 Products',
            isTr ? '🤔 Bugün ne yesem?' : '🤔 What to eat?',
          ],
        ),
      );
    } else {
      // General instructions fallback - specifically stating we don't have info/scope about other topics
      _messages.add(
        ChatMessage(
          text: isTr
              ? 'Aradığınız konu hakkında bilgim bulunmamaktadır. 😔 Ben sadece yemekhane menüsü, yemeklerin besin değerleri/kalorileri ve sipariş durumu ile ilgili bilgi verebiliyorum. Lütfen bu konularla ilgili bir soru sorun ya da aşağıdaki butonlara tıklayın!'
              : 'I do not have information about this topic. 😔 I can only assist with the cafeteria menu, meal calories/nutrients, and order tracking. Please ask a question related to these topics or click one of the buttons below!',
          isBot: true,
          quickReplies: _getInitialReplies(lang),
        ),
      );
    }
  }
}
