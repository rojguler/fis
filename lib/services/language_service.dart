import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

/// Provides translated strings for EN / TR and persists the choice.
class LanguageService extends ChangeNotifier {
  static const _key = 'language_code';

  String _code = 'en'; // 'en' or 'tr'
  String get code => _code;
  bool get isTurkish => _code == 'tr';

  LanguageService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString(_key) ?? 'en';
    notifyListeners();
  }

  Future<void> toggle() async {
    _code = isTurkish ? 'en' : 'tr';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _code);
  }

  // ──────────────────────────────────────────────
  //  Strings
  // ──────────────────────────────────────────────
  String get home        => isTurkish ? 'Ana Sayfa'    : 'Home';
  String get menu        => isTurkish ? 'Menü'         : 'Menu';
  String get orders      => isTurkish ? 'Siparişler'   : 'Orders';
  String get profile     => isTurkish ? 'Profil'       : 'Profile';
  String get cart        => isTurkish ? 'Sepet'        : 'Cart';
  String get todayMenu   => isTurkish ? 'Bugünün Menüsü' : "Today's Menu";
  String get allProducts => isTurkish ? 'Tüm Ürünler'  : 'All Products';
  String get settings    => isTurkish ? 'Ayarlar'      : 'Settings';
  String get darkMode    => isTurkish ? 'Karanlık Mod' : 'Dark Mode';
  String get language    => isTurkish ? 'Dil'          : 'Language';
  String get signOut     => isTurkish ? 'Çıkış Yap'   : 'Sign Out';
  String get myOrders    => isTurkish ? 'Siparişlerim' : 'My Orders';
  String get inStock     => isTurkish ? 'Stokta Var'   : 'In Stock';
  String get outOfStock  => isTurkish ? 'Stok Yok'     : 'Out of Stock';
  String get orderTracking => isTurkish ? 'Sipariş Takibi' : 'Order Tracking';
  String get editProfile   => isTurkish ? 'Profili Düzenle' : 'Edit Profile';
  String get save          => isTurkish ? 'Kaydet'      : 'Save';
  String get cancel        => isTurkish ? 'İptal'       : 'Cancel';
  String get displayName   => isTurkish ? 'Ad Soyad'   : 'Full Name';
  String get languageName  => isTurkish ? 'Türkçe'  : 'English';
  
  // Home Screen
  String get searchHint    => isTurkish ? 'Yemeklerde ara...' : 'Search for meals...';
  String get hello         => isTurkish ? 'Merhaba' : 'Hello';
  String get checkOutTodayMenu => isTurkish ? 'Bugünün menüsüne göz at' : "Check out today's menu";
  String get noResults     => isTurkish ? 'Sonuç bulunamadı' : 'No results found';
  String get noMealsToday  => isTurkish ? 'Bugün menü yok' : 'No meals today';
  String get tryAdjusting  => isTurkish ? 'Aramayı veya filtreleri değiştirmeyi deneyin' : 'Try adjusting your search or filters';
  String get clearFilters  => isTurkish ? 'Filtreleri Temizle' : 'Clear Filters';
  String get itemsCount    => isTurkish ? 'ürün' : 'items';
  String get leftCount     => isTurkish ? 'kaldı' : 'Left';
  
  // Category Chips
  String get catAll        => isTurkish ? 'Tümü' : 'All';
  String get catMain       => isTurkish ? 'Ana Yemek' : 'Main';
  String get catSoup       => isTurkish ? 'Çorba' : 'Soup';
  String get catSalad      => isTurkish ? 'Salata' : 'Salad';
  String get catDessert    => isTurkish ? 'Tatlı' : 'Dessert';
  String get catDrink      => isTurkish ? 'İçecek' : 'Drink';
  String get catDiet       => isTurkish ? 'Diyet' : 'Diet';
  
  // Notifications
  String get itemAddedCart => isTurkish ? 'Sepete eklendi!' : 'Item added to cart!';
  String get itemUpdatedCart => isTurkish ? 'Miktar güncellendi!' : 'Quantity updated!';
  String get itemRemovedCart => isTurkish ? 'Sepetten çıkarıldı!' : 'Item removed from cart!';
  String get cartCleared   => isTurkish ? 'Sepet temizlendi' : 'Cart cleared!';
  String get pleaseLogin   => isTurkish ? 'Yorum yapmak için giriş yapın' : 'Please login to review';
  String get pleaseComment => isTurkish ? 'Lütfen bir yorum yazın' : 'Please write a comment';
  String get reviewDone    => isTurkish ? 'Yorumunuz başarıyla gönderildi!' : 'Review submitted successfully!';
  String get comingSoon    => isTurkish ? 'Çok yakında!' : 'Coming soon!';
  String get passMismatch  => isTurkish ? 'Şifreler eşleşmiyor!' : 'Passwords do not match!';
  String get authError     => isTurkish ? 'Kimlik doğrulama hatası:' : 'Authentication error:';
  String get loginSuccess  => isTurkish ? 'Giriş başarılı!' : 'Login successful!';
  String get signupSuccess => isTurkish ? 'Kayıt başarılı!' : 'Signup successful!';
  String get profileUpdated => isTurkish ? 'Profil güncellendi!' : 'Profile updated!';
  String get profilePicUpdated => isTurkish ? 'Profil fotoğrafı güncellendi!' : 'Profile picture updated!';
  String get orderCreated  => isTurkish ? 'Siparişiniz başarıyla oluşturuldu!' : 'Order created successfully!';
  String get copyToClipboard => isTurkish ? 'Panoya kopyalandı!' : 'Copied to clipboard!';
  String get failedToCreateOrder => isTurkish ? 'Sipariş oluşturulamadı:' : 'Failed to create order:';
  String get errorOccurred => isTurkish ? 'Bir hata oluştu:' : 'Error:';
  String get orderUpdated  => isTurkish ? 'Sipariş Güncellendi' : 'Order Updated';

  // Profile specific
  String get refresh       => isTurkish ? 'Yenile' : 'Refresh';
  String get preferences   => isTurkish ? 'Tercihler' : 'Preferences';
  String get darkOn        => isTurkish ? 'Karanlık tema açık' : 'Dark theme is on';
  String get lightOn       => isTurkish ? 'Aydınlık tema açık' : 'Light theme is on';
  String get accountInfo   => isTurkish ? 'Hesap Bilgileri' : 'Account Information';
  String get accountSub    => isTurkish ? 'Profil detaylarınızı görüntüleyin' : 'View your profile details';
  String get helpSupport   => isTurkish ? 'Yardım ve Destek' : 'Help & Support';
  String get helpSub       => isTurkish ? 'Destek ekibimizle iletişime geçin' : 'Contact our support team';
  String get about         => isTurkish ? 'Hakkında' : 'About';
  String get aboutSub      => isTurkish ? 'Uygulama sürümü ve bilgileri' : 'App version & info';
  String get confirmSignOut=> isTurkish ? 'Çıkış yapmak istediğinize emin misiniz?' : 'Are you sure you want to sign out?';
  String get noOrdersYet   => isTurkish ? 'Henüz sipariş yok' : 'No orders yet';
  String get noOrdersSub   => isTurkish ? 'Sipariş geçmişiniz burada görünecektir' : 'Your order history will appear here';
  String get close         => isTurkish ? 'Kapat' : 'Close';

  // Push Notifications (Order Status)
  String get orderUpdatePrefix => isTurkish ? 'Sipariş Güncellemesi: Siparişiniz ' : 'Order Update: Your order ';
  String get orderPreparing => isTurkish ? 'hazırlanıyor! 🍳' : 'is being prepared! 🍳';
  String get orderReady    => isTurkish ? 'teslime hazır! Lütfen teslim alın. 🎉' : 'is ready for pickup! 🎉';
  String get orderCompleted=> isTurkish ? 'teslim edildi. Afiyet olsun!' : 'is completed. Enjoy!';
  String get orderCancelled=> isTurkish ? 'iptal edildi.' : 'was cancelled.';
  // Order Tracking & Creation
  String get orderProgress => isTurkish ? 'Sipariş Durumu' : 'Order Progress';
  String get orderDetails  => isTurkish ? 'Sipariş Detayları' : 'Order Details';
  String get items         => isTurkish ? 'Ürünler' : 'Items';
  String get total         => isTurkish ? 'Toplam' : 'Total';
  String get reorder       => isTurkish ? 'Tekrar Sipariş Ver' : 'Reorder these items';
  String get itemsAdded    => isTurkish ? 'Ürünler sepete eklendi!' : 'Items added to cart!';
  String get notesOptional => isTurkish ? 'Notlar (Opsiyonel)' : 'Notes (Optional)';
  String get notesHint     => isTurkish ? 'Siparişinizle ilgili özel not ekleyin...' : 'Add any special notes about your order...';
  String get createOrder   => isTurkish ? 'Sipariş Oluştur' : 'Create Order';
  String get paymentInfo   => isTurkish ? 'Ödeme Bilgisi' : 'Payment Information';
  String get paymentWait   => isTurkish ? 'Siparişiniz oluşturulduktan sonra ödemeyi yemekhanede yapabilirsiniz. Uygulama üzerinden ödeme alınmamaktadır.' : 'After your order is created, you can go to the cafeteria to make payment. Payment is not made through the app.';
  String get pleaseSignIn  => isTurkish ? 'Devam etmek için lütfen giriş yapın' : 'Please sign in to continue';
  String get orderSuccess  => isTurkish ? 'Sipariş başarıyla oluşturuldu!' : 'Order created successfully!';

  // Order Status Messages
  String get statusPendingMsg   => isTurkish ? 'Siparişiniz onay bekliyor' : 'Your order is waiting to be accepted';
  String get statusPreparingMsg => isTurkish ? 'Mutfak siparişinizi hazırlıyor' : 'Kitchen is preparing your order';
  String get statusReadyMsg     => isTurkish ? 'Siparişiniz teslim alınmaya hazır!' : 'Your order is ready for pickup!';
  String get statusCompletedMsg => isTurkish ? 'Sipariş tamamlandı. Afiyet olsun!' : 'Order completed. Enjoy!';
  String get statusCancelledMsg => isTurkish ? 'Bu sipariş iptal edildi' : 'This order was cancelled';

  // Status Labels
  String statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:   return isTurkish ? 'Sipariş Alındı' : 'Order Received';
      case OrderStatus.preparing: return isTurkish ? 'Hazırlanıyor' : 'Preparing';
      case OrderStatus.ready:     return isTurkish ? 'Hazır' : 'Ready';
      case OrderStatus.completed: return isTurkish ? 'Tamamlandı' : 'Completed';
      case OrderStatus.cancelled: return isTurkish ? 'İptal Edildi' : 'Cancelled';
    }
  }

  // Admin Notifications
  String get adminNewOrder => isTurkish ? 'Yeni Sipariş Geldi! 🔔' : 'New Order Received! 🔔';
  String get adminNewOrderSub => isTurkish ? 'Lütfen sipariş panosunu kontrol edin.' : 'Please check the order dashboard.';

  // Advanced Filters
  String get filters      => isTurkish ? 'Filtreler'    : 'Filters';
  String get proteinAmount => isTurkish ? 'Protein Miktarı' : 'Protein Amount';
  String get carbAmount    => isTurkish ? 'Karbonhidrat Miktarı' : 'Carbohydrate Amount';
  String get minProtein    => isTurkish ? 'Min Protein (g)' : 'Min Protein (g)';
  String get maxCarbs      => isTurkish ? 'Maks Karb (g)' : 'Max Carbs (g)';
  String get allergensToExclude => isTurkish ? 'Hariç Tutulacak Alerjenler' : 'Allergens to Exclude';
  String get resetFilters  => isTurkish ? 'Filtreleri Sıfırla' : 'Reset Filters';
  String get applyFilters  => isTurkish ? 'Filtreleri Uygula' : 'Apply Filters';
  String get highProtein   => isTurkish ? 'Yüksek Protein (>20g)' : 'High Protein (>20g)';
  String get lowCarb       => isTurkish ? 'Düşük Karbonhidrat (<30g)' : 'Low Carb (<30g)';

  // Auth Screens
  String get welcomeBack   => isTurkish ? 'Tekrar Hoş Geldiniz!' : 'Welcome Back!';
  String get signInToAcc   => isTurkish ? 'Hesabınıza giriş yapın' : 'Sign in to your account';
  String get emailAddress  => isTurkish ? 'E-posta Adresi' : 'Email Address';
  String get password      => isTurkish ? 'Şifre' : 'Password';
  String get signIn        => isTurkish ? 'Giriş Yap' : 'Sign In';
  String get signUp        => isTurkish ? 'Kayıt Ol' : 'Sign Up';
  String get dontHaveAcc   => isTurkish ? 'Hesabınız yok mu?' : "Don't have an account?";
  String get createAcc     => isTurkish ? 'Hesap Oluştur' : 'Create Account';
  String get joinIkas      => isTurkish ? 'IKAS Fis\'e Katılın' : 'Join IKAS Fis';
  String get fullName      => isTurkish ? 'Ad Soyad' : 'Full Name';
  String get confirmPass   => isTurkish ? 'Şifreyi Onayla' : 'Confirm Password';
  String get adminCode     => isTurkish ? 'Yönetici Kodu (Opsiyonel)' : 'Admin Code (Optional)';
  String get adminCodeSub  => isTurkish ? 'Yöneticiyseniz kodunuzu girin' : 'Enter admin code if you are an administrator';
  String get adminCodeInfo => isTurkish ? 'Normal kullanıcı için boş bırakın' : 'Leave empty for regular user account';
  String get alreadyHaveAcc => isTurkish ? 'Zaten hesabınız var mı?' : 'Already have an account?';
  String get loginNow      => isTurkish ? 'Giriş Yapın' : 'Login Now';

  // Additional Cart & UI
  String get currency      => isTurkish ? '₺' : '₺';
  String get clearCart     => isTurkish ? 'Sepeti Temizle' : 'Clear Cart';
  String get confirmClearCart => isTurkish ? 'Sepetinizdeki tüm ürünleri silmek istediğinize emin misiniz?' : 'Are you sure you want to clear your cart?';
  String get nutritionSummary => isTurkish ? 'Besin Değerleri Özeti' : 'Nutrition Summary';
  String get payAtCafeteria => isTurkish ? 'Ödemeyi Marketten Yapın' : 'Pay at Market';
  String get showOrder     => isTurkish ? 'Siparişi Göster' : 'Show Order';
  String get orderNum      => isTurkish ? 'Sipariş No' : 'Order No';
  String get backToHome    => isTurkish ? 'Ana Sayfaya Dön' : 'Back to Home';
  String get goToTracking  => isTurkish ? 'Takip Et' : 'Track Order';

  String maxLimitReached(int limit) => isTurkish ? 'Ürün başına maksimum sınır $limit adettir' : 'Maximum limit per item is $limit';
  String maxStockReached(int stock) => isTurkish ? 'Maksimum stok: $stock' : 'Maximum stock: $stock';
  String get cartHasUnavailableItems => isTurkish ? 'Sepetinizde stokta olmayan ürünler var' : 'Your cart contains out of stock items';
  String get orderReceived => isTurkish ? 'Siparişiniz alındı ve hazırlanmaya başlanacak.' : 'Your order has been received and will be prepared soon.';
  String get demoMode => isTurkish ? 'Demo Modu' : 'Demo Mode';
  String get liveUpdates => isTurkish ? 'Canlı Güncellemeler' : 'Live Updates';
  String get itemsAddedToCart => isTurkish ? 'Ürünler sepete eklendi!' : 'Items added to cart!';
  String get trendingNow => isTurkish ? 'Popüler Ürünler' : 'Trending Now';
  String get nutritionFacts => isTurkish ? 'Besin Değerleri' : 'Nutrition Facts';
  String get description => isTurkish ? 'Ürün Açıklaması' : 'Description';
  String get shareMeal => isTurkish ? 'Yemeği Paylaş' : 'Share Meal';
  String get kcal => isTurkish ? 'kal' : 'kcal';
  String get proteinG => isTurkish ? 'g protein' : 'g protein';
  String get reviews => isTurkish ? 'Yorumlar ve Değerlendirmeler' : 'Reviews & Ratings';
  String get rateThisMeal => isTurkish ? 'Bu yemeği değerlendir' : 'Rate this meal';
  String get shareThoughts => isTurkish ? 'Düşüncelerinizi paylaşın...' : 'Share your thoughts...';
  String get submitReview => isTurkish ? 'Yorumu Gönder' : 'Submit Review';
  String get price => isTurkish ? 'Fiyat' : 'Price';
  String get relatedMeals => isTurkish ? 'Benzer Ürünler' : 'Related Products';
  String get allergens => isTurkish ? 'Alerjenler' : 'Allergens';
  String get noReviewsYet => isTurkish ? 'Henüz yorum yok.' : 'No reviews yet.';
  String get beFirstToReview => isTurkish ? 'İlk yorumu sen yap!' : 'Be the first to review!';
  String get mustSignInToReview => isTurkish ? 'Yorum yapmak için giriş yapmalısınız.' : 'Please sign in to leave a review.';
  String get orderToReview => isTurkish ? 'Yorum yapmak için önce bu ürünü sipariş etmelisiniz.' : 'You can review this item after ordering it.';
  String get recentSearches => isTurkish ? 'Son Aramalar' : 'Recent Searches';
  String get clearAll => isTurkish ? 'Tümünü Temizle' : 'Clear all';
  String get sortedBy => isTurkish ? 'Sıralama:' : 'Sorted by';
  String get voiceSearchSoon => isTurkish ? 'Sesli arama yakında!' : 'Voice search coming soon!';

  // --- Email & Service specific ---
  String get emailOrderConfirmationSubject => isTurkish ? 'Siparişiniz Alındı! 📝' : 'Order Received! 📝';
  String get emailOrderConfirmationBody => isTurkish ? 'Siparişiniz başarıyla alındı ve mutfağa iletildi. Marketten teslim alırken ödeme yapabilirsiniz.' : 'Your order has been received and sent to the kitchen. You can pay when picking up from the market.';
  String get emailOrderStatusSubject => isTurkish ? 'Sipariş Durumu Güncellendi 🔔' : 'Order Status Updated 🔔';
  String get emailOrderStatusBodyPrefix => isTurkish ? 'Siparişiniz şu an şu durumda: ' : 'Your order is currently: ';
  String get emailOrderNo => isTurkish ? 'Sipariş Numarası: ' : 'Order Number: ';
  String get emailTotalAmount => isTurkish ? 'Toplam Tutar: ' : 'Total Amount: ';
  String get emailHello => isTurkish ? 'Merhaba' : 'Hello';
  String get emailThankYou => isTurkish ? 'Bizi tercih ettiğiniz için teşekkürler!' : 'Thank you for choosing us!';

  // --- Auth Errors & Verification ---
  String get verifyEmailSent => isTurkish ? 'Doğrulama e-postası gönderildi. Lütfen gelen kutunuzu kontrol edin.' : 'Verification email sent. Please check your inbox.';
  String get emailNotVerified => isTurkish ? 'Lütfen e-postanızı doğrulayın.' : 'Please verify your email address.';
  String get invalidAdminCode => isTurkish ? 'Geçersiz admin kodu!' : 'Invalid admin code!';
  String get accountCreatedVerify => isTurkish ? 'Hesap başarıyla oluşturuldu. Giriş yapmak için e-postanızı doğrulayın.' : 'Account created successfully. Please verify your email to log in.';

  // --- Auth Error Mappings ---
  String get errUserNotFound => isTurkish ? 'Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı.' : 'No user found with this email address.';
  String get errWrongPassword => isTurkish ? 'Hatalı şifre girdiniz. Lütfen tekrar deneyin.' : 'Wrong password. Please try again.';
  String get errEmailInUse => isTurkish ? 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.' : 'This email is already in use by another account.';
  String get errWeakPassword => isTurkish ? 'Şifreniz çok zayıf. Lütfen daha güçlü bir şifre seçin.' : 'The password is too weak. Please choose a stronger password.';
  String get errInvalidEmail => isTurkish ? 'Geçersiz bir e-posta adresi girdiniz.' : 'The email address is invalid.';
  String get errUserDisabled => isTurkish ? 'Bu kullanıcı hesabı devre dışı bırakılmış.' : 'This user account has been disabled.';
  String get errTooManyRequests => isTurkish ? 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.' : 'Too many failed attempts. Please try again later.';
  String get errOperationNotAllowed => isTurkish ? 'Bu işleme şu an izin verilmiyor.' : 'This operation is not allowed.';
  String get errDefault => isTurkish ? 'Bir hata oluştu. Lütfen tekrar deneyin.' : 'An error occurred. Please try again.';
}
