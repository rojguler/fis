import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/seed_service.dart';
import '../widgets/shimmer_loading.dart';
import '../services/menu_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import 'meal_detail_screen.dart';
import 'cart_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';
import 'package:ikas_fis/models/order.dart' as models;
import '../services/order_service.dart';
import 'order_tracking_screen.dart';
import '../services/language_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onExploreNow;
  const HomeScreen({super.key, this.onExploreNow});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  // Alerjen / Diyet filtreleri
  bool _filterVegan = false;
  bool _filterGlutenFree = false;

  LanguageService get lang => Provider.of<LanguageService>(context, listen: false);
  Timer? _promoTimer;
  int _promoCurrent = 0;
  final PageController _promoController = PageController(viewportFraction: 0.92);

  @override
  void initState() {
    super.initState();
    _startPromoTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuService = Provider.of<MenuService>(context, listen: false);
      menuService.fetchAllMeals();
      menuService.fetchTodayMenu();
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _searchController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _startPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_promoController.hasClients) {
        int next = _promoCurrent + 1;
        if (next >= 3) next = 0; // Assuming 3 banners
        _promoController.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  List<dynamic> _filterMeals(List<dynamic> meals) {
    var filtered = meals;
    if (_selectedCategory != 'all') {
      filtered = filtered.where((m) => m.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        return m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m.nameTr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m.descriptionTr.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    if (_filterVegan) {
      filtered = filtered.where((m) => m.isVegan == true).toList();
    }
    if (_filterGlutenFree) {
      filtered = filtered.where((m) => m.isGlutenFree == true).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? IKASColors.darkBg : IKASColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  color: IKASColors.primary,
                  onRefresh: () async {
                    final ms = Provider.of<MenuService>(context, listen: false);
                    await ms.fetchAllMeals();
                    await ms.fetchTodayMenu();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildSearch()),
                      SliverToBoxAdapter(child: _buildPromoBanner()),
                      Consumer<MenuService>(
                        builder: (context, menuService, _) {
                          // Günlük menü varsa sadece onu göster; yoksa tüm menü
                          final hasDailyMenu = menuService.todayMeals.isNotEmpty;
                          final sourceList = hasDailyMenu ? menuService.todayMeals : menuService.meals;
                          final filteredMeals = _filterMeals(sourceList);

                          return SliverList(
                            delegate: SliverChildListDelegate([
                              _buildActiveOrderTrackerWidget(context),
                              if (hasDailyMenu && _searchQuery.isEmpty && _selectedCategory == 'all')
                                _buildDailyMenuBanner(context),
                              if (_searchQuery.isEmpty && _selectedCategory == 'all' && !hasDailyMenu && sourceList.isNotEmpty)
                                _buildTrendingNow(sourceList),
                              if (hasDailyMenu && _searchQuery.isEmpty && _selectedCategory == 'all')
                                _buildStoryMenu(menuService.todayMeals),
                              _buildChips(),
                              _buildDietFilters(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                                child: Row(
                                  children: [
                                    Text(
                                      lang.isTurkish ? 'Tüm Menü' : 'Full Menu',
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : IKASColors.textDark,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!menuService.isLoading)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: IKASColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${filteredMeals.length} ${lang.itemsCount}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: IKASColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (menuService.isLoading && filteredMeals.isEmpty)
                                ...List.generate(3, (index) => const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: MealCardShimmer(),
                                ))
                              else if (filteredMeals.isEmpty)
                                _buildEmptyStateWidget(context)
                              else
                                ...filteredMeals.map((m) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: _mealCard(context, m),
                                )),
                              const SizedBox(height: 120),
                            ]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Consumer<CartService>(
            builder: (context, cart, _) {
              if (cart.itemCount == 0) return const SizedBox.shrink();
              return Positioned(
                bottom: 24, left: 16, right: 16,
                child: _buildFloatingCart(context, cart),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [IKASColors.primaryDark, IKASColors.primary, IKASColors.accent],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('IKAS Super Market', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  Consumer<AuthService>(
                    builder: (_, auth, __) => auth.isAdmin
                        ? _iconBtn(Icons.admin_panel_settings_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())))
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Consumer<CartService>(
                    builder: (_, cart, __) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _iconBtn(Icons.shopping_bag_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
                        if (cart.itemCount > 0)
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              width: 17, height: 17,
                              decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                              child: Center(child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _iconBtn(Icons.refresh_rounded, () async {
                    final ms = Provider.of<MenuService>(context, listen: false);
                    await SeedService.seedIfEmpty();
                    await ms.fetchAllMeals();
                    await ms.fetchTodayMenu();
                  }),
                  const SizedBox(width: 8),
                  Consumer<AuthService>(
                    builder: (_, auth, __) {
                      final name = auth.currentUserName;
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5)),
                          child: Center(child: Text(initial, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<AuthService>(
                builder: (_, auth, __) {
                  final name = auth.currentUserName;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isNotEmpty ? '${lang.hello}, $name 👋' : '${lang.hello}! 👋', style: GoogleFonts.poppins(fontSize: 21, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(lang.checkOutTodayMenu, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.82))),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white.withOpacity(0.35))),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  Widget _buildSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: lang.searchHint,
          prefixIcon: const Icon(Icons.search_rounded, color: IKASColors.primary),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded, color: IKASColors.textLight, size: 20), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; })) : null,
          filled: true,
          fillColor: isDark ? IKASColors.darkCard : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? IKASColors.primaryLight : IKASColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _chip(String cat, String label, String? imagePath, IconData? icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = cat),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? IKASColors.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? IKASColors.darkCard : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                  image: imagePath != null ? DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: imagePath == null ? Icon(icon, color: IKASColors.primary, size: 28) : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? IKASColors.primary : (isDark ? Colors.white70 : IKASColors.textMid),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips() {
    return Container(
      height: 115,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('all', lang.catAll, null, Icons.grid_view_rounded),
          _chip('main', lang.catMain, 'assets/images/musakka.jpg', null),
          _chip('soup', lang.catSoup, 'assets/images/brokoli_corbasi.jpg', null),
          _chip('salad', lang.catSalad, 'assets/images/sezar_salatasi.jpg', null),
          _chip('dessert', lang.catDessert, 'assets/images/cikolatali_browni.jpg', null),
          _chip('drink', lang.catDrink, 'assets/images/limonata.jpg', null),
          _chip('diet', lang.catDiet, 'assets/images/granola_bowl.jpg', null),
        ],
      ),
    );
  }

  Widget _buildDietFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _dietChip(
            label: 'Vegan', 
            icon: Icons.eco_rounded,
            active: _filterVegan, 
            activeColor: Colors.green.shade600, 
            onTap: () => setState(() => _filterVegan = !_filterVegan), 
            isDark: isDark
          ),
          const SizedBox(width: 12),
          _dietChip(
            label: lang.isTurkish ? 'Glutensiz' : 'Gluten-Free', 
            icon: Icons.verified_rounded,
            active: _filterGlutenFree, 
            activeColor: Colors.amber.shade800, 
            onTap: () => setState(() => _filterGlutenFree = !_filterGlutenFree), 
            isDark: isDark
          ),
        ],
      ),
    );
  }

  Widget _dietChip({required String label, required IconData icon, required bool active, required Color activeColor, required VoidCallback onTap, required bool isDark}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? activeColor : (isDark ? IKASColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? activeColor : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: 2,
            ),
            boxShadow: active ? [
              BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5))
            ] : [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : activeColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : (isDark ? Colors.white70 : IKASColors.textMid),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyMenuBanner(BuildContext context) {
    final menuService = Provider.of<MenuService>(context, listen: false);
    final count = menuService.todayMeals.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [IKASColors.primaryDark.withOpacity(0.9), IKASColors.accent.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: IKASColors.primary.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Text('📋', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.isTurkish ? 'Günün Menüsü Aktif' : 'Daily Menu Active',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                ),
                Text(
                  lang.isTurkish
                      ? 'Bugün sadece $count ürün satışta'
                      : 'Only $count items available today',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              lang.isTurkish ? 'Bugün' : 'Today',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuService = Provider.of<MenuService>(context, listen: false);
    final noDailyMenu = menuService.todayMeals.isEmpty && menuService.meals.isEmpty && _searchQuery.isEmpty && _selectedCategory == 'all';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 110, height: 110, decoration: BoxDecoration(color: IKASColors.primary.withOpacity(0.12), shape: BoxShape.circle), child: Center(child: Text(noDailyMenu ? '🍽️' : '🔍', style: const TextStyle(fontSize: 44)))),
            const SizedBox(height: 24),
            Text(noDailyMenu ? (lang.isTurkish ? 'Bugün Menü Yok' : 'No Menu Today') : lang.noResults, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : IKASColors.textDark), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(noDailyMenu ? (lang.isTurkish ? 'Şeflerimiz bugün için özel bir menü hazırlıyor.' : 'Our chefs are crafting a special menu.') : lang.isTurkish ? 'Filtreleri değiştirmeyi dene.' : 'Try changing filters.', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            if (noDailyMenu)
              ElevatedButton.icon(onPressed: () async { await SeedService.forceSeed(); menuService.fetchAllMeals(); menuService.fetchTodayMenu(); }, icon: const Icon(Icons.download_rounded), label: Text(lang.isTurkish ? 'Örnek Verileri Yükle' : 'Seed Sample Data')),
          ],
        ),
      ),
    );
  }

  Widget _mealCard(BuildContext context, dynamic meal) {
    final isAvailable = meal.isAvailable as bool;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        decoration: BoxDecoration(color: isDark ? IKASColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 25, offset: const Offset(0, 10))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Row(
                children: [
                  Padding(padding: const EdgeInsets.all(12), child: Hero(tag: 'meal-${meal.id}', child: Container(width: 100, height: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)), child: ClipRRect(borderRadius: BorderRadius.circular(22), child: _buildMealImage(meal.imageUrl ?? '', isAvailable))))),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meal.getLocalizedName(lang.isTurkish), style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : IKASColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(meal.getLocalizedDescription(lang.isTurkish), style: GoogleFonts.poppins(fontSize: 11, color: IKASColors.textMid), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Text('${meal.price.toStringAsFixed(2)} ₺', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: IKASColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: isAvailable ? () { Provider.of<CartService>(context, listen: false).addItem(meal); } : null, child: Container(width: 44, height: 40, decoration: BoxDecoration(color: isAvailable ? IKASColors.primary : Colors.grey.withOpacity(0.3), borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomRight: Radius.circular(24))), child: const Icon(Icons.add_rounded, color: Colors.white, size: 24)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealImage(String imageUrl, bool isAvailable) {
    if (imageUrl.isEmpty) return Container(color: Colors.grey.shade300, child: const Icon(Icons.restaurant, color: Colors.white));
    if (imageUrl.startsWith('http')) return CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover);
    if (imageUrl.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(imageUrl.split(',')[1]),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.restaurant, color: Colors.white)),
        );
      } catch (_) {
        return Container(color: Colors.grey.shade300, child: const Icon(Icons.restaurant, color: Colors.white));
      }
    }
    return Image.asset(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.restaurant, color: Colors.white)));
  }

  Widget _buildPromoBanner() {
    final isTr = Provider.of<LanguageService>(context, listen: false).isTurkish;
    final banners = [
      _BannerData(
        title: isTr ? '🔥 Bugüne Özel %20 İndirim' : '🔥 20% Off Today',
        subtitle: isTr ? 'Tüm çorbalarda geçerli!' : 'Valid on all soups!',
        icon: Icons.local_fire_department_rounded,
        colors: [const Color(0xFFFF6B35), const Color(0xFFD62828)],
      ),
      _BannerData(
        title: isTr ? '🥗 Taze Yaz Salataları' : '🥗 Fresh Summer Salads',
        subtitle: isTr ? '%15 İndirimli!' : '15% Discount!',
        icon: Icons.eco_rounded,
        colors: [IKASColors.primaryDark, IKASColors.accent],
      ),
      _BannerData(
        title: isTr ? '☕ Kahvaltı Keyfi' : '☕ Breakfast Specials',
        subtitle: isTr ? 'Güne zinde başla' : 'Start your day right',
        icon: Icons.free_breakfast_rounded,
        colors: [const Color(0xFF6C3483), const Color(0xFFA569BD)],
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _promoController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _promoCurrent = i),
            itemBuilder: (_, i) => _bannerItem(banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _promoCurrent == i ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _promoCurrent == i ? IKASColors.primary : IKASColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    );
  }

  Widget _bannerItem(_BannerData data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: data.colors), borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(data.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)), Text(data.subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70))])),
          Icon(data.icon, size: 40, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildActiveOrderTrackerWidget(BuildContext context) {
    return Consumer<OrderService>(
      builder: (context, orderService, _) {
        final activeOrder = orderService.orders.isEmpty ? null : orderService.orders.firstWhere((o) => o.status != models.OrderStatus.completed && o.status != models.OrderStatus.cancelled, orElse: () => orderService.orders.first);
        if (activeOrder == null || activeOrder.status == models.OrderStatus.completed || activeOrder.status == models.OrderStatus.cancelled) return const SizedBox.shrink();
        final statusColor = activeOrder.status == models.OrderStatus.ready ? IKASColors.primary : Colors.orange;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: activeOrder))),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: IKASColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: statusColor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(lang.isTurkish ? 'Siparişin Hazırlanıyor' : 'Order Preparing', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: statusColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingCart(BuildContext context, CartService cart) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: IKASColors.primary, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text('${cart.itemCount} ${lang.isTurkish ? 'Ürün' : 'Items'} | ₺${cart.totalPrice.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))),
            Text(lang.isTurkish ? 'Sepete Git' : 'View Cart', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingNow(List<dynamic> meals) {
    final trending = meals.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(20), child: Text(lang.trendingNow, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800))),
        SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: trending.length, itemBuilder: (context, i) => _buildTrendingCard(trending[i]))),
      ],
    );
  }

  Widget _buildTrendingCard(dynamic meal) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal))),
      child: Container(width: 140, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(children: [Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(22)), child: _buildMealImage(meal.imageUrl, true))), Padding(padding: const EdgeInsets.all(8), child: Text(meal.getLocalizedName(lang.isTurkish), maxLines: 1, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)))])),
    );
  }

  Widget _buildStoryMenu(List<dynamic> meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(20), child: Text(lang.isTurkish ? 'Günün Menüsü' : 'Today Specials', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold))),
        SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: meals.length, itemBuilder: (context, i) => GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meals[i]))), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [CircleAvatar(radius: 30, backgroundColor: Colors.grey.shade200, child: ClipOval(child: SizedBox(width: 60, height: 60, child: _buildMealImage(meals[i].imageUrl, true)))), const SizedBox(height: 4), Text(meals[i].getLocalizedName(lang.isTurkish), style: const TextStyle(fontSize: 10))]))))),
      ],
    );
  }
}

class _AnimatedPulseIcon extends StatefulWidget {
  final Color color;
  const _AnimatedPulseIcon({required this.color});
  @override
  State<_AnimatedPulseIcon> createState() => _AnimatedPulseIconState();
}

class _AnimatedPulseIconState extends State<_AnimatedPulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return const Icon(Icons.restaurant_rounded, color: Colors.white); }
}

class _BannerData {
  final String title; final String subtitle; final IconData icon; final List<Color> colors;
  const _BannerData({required this.title, required this.subtitle, required this.icon, required this.colors});
}
