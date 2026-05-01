import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../main.dart';
import '../services/menu_service.dart';
import '../models/meal.dart';
import '../services/order_service.dart';
import 'order_management_screen.dart';
import '../services/language_service.dart';
import '../services/seed_service.dart';
import '../services/coupon_service.dart';

// Admin screen for managing daily menus (add, update, delete)
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: isDark ? IKASColors.darkBg : Colors.grey[50],
      appBar: AppBar(
        title: Text('Admin Panel', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : IKASColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              Provider.of<MenuService>(context, listen: false).fetchAllMeals();
              Provider.of<MenuService>(context, listen: false).fetchTodayMenu();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.redAccent),
            tooltip: 'Reset & Fix Localization',
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      body: isWide 
        ? Row(
            children: [
              // Sidebar navigation for wide screens
              NavigationRail(
                backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
                selectedIconTheme: const IconThemeData(color: IKASColors.primary),
                unselectedIconTheme: IconThemeData(color: isDark ? Colors.white54 : Colors.grey[600]),
                selectedLabelTextStyle: GoogleFonts.poppins(color: IKASColors.primary, fontWeight: FontWeight.bold),
                unselectedLabelTextStyle: GoogleFonts.poppins(color: isDark ? Colors.white54 : Colors.grey[600]),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard_rounded), label: Text(lang.isTurkish ? 'Panel' : 'Dashboard')),
                  NavigationRailDestination(icon: const Icon(Icons.restaurant_menu), selectedIcon: const Icon(Icons.restaurant_menu), label: Text(lang.isTurkish ? 'Menü' : 'Menu')),
                  NavigationRailDestination(icon: const Icon(Icons.calendar_today), selectedIcon: const Icon(Icons.calendar_today), label: Text(lang.isTurkish ? 'Günlük Menü' : 'Daily Menu')),
                  NavigationRailDestination(icon: const Icon(Icons.receipt_long), selectedIcon: const Icon(Icons.receipt_long), label: Text(lang.isTurkish ? 'Siparişler' : 'Orders')),
                  NavigationRailDestination(icon: const Icon(Icons.local_offer_outlined), selectedIcon: const Icon(Icons.local_offer_rounded), label: Text(lang.isTurkish ? 'Kuponlar' : 'Coupons')),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              
              // Main content
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          )
        : _buildMainContent(),
      bottomNavigationBar: !isWide 
        ? BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
            selectedItemColor: IKASColors.primary,
            unselectedItemColor: isDark ? Colors.white54 : Colors.grey[600],
            selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), activeIcon: const Icon(Icons.dashboard_rounded), label: lang.isTurkish ? 'Panel' : 'Dashboard'),
              BottomNavigationBarItem(icon: const Icon(Icons.restaurant_menu), activeIcon: const Icon(Icons.restaurant_menu), label: lang.isTurkish ? 'Menü' : 'Menu'),
              BottomNavigationBarItem(icon: const Icon(Icons.calendar_today), activeIcon: const Icon(Icons.calendar_today), label: lang.isTurkish ? 'Günlük' : 'Daily'),
              BottomNavigationBarItem(icon: const Icon(Icons.receipt_long), activeIcon: const Icon(Icons.receipt_long), label: lang.isTurkish ? 'Siparişler' : 'Orders'),
              BottomNavigationBarItem(icon: const Icon(Icons.local_offer_outlined), activeIcon: const Icon(Icons.local_offer_rounded), label: lang.isTurkish ? 'Kuponlar' : 'Coupons'),
            ],
          )
        : null,
    );
  }

  Widget _buildMainContent() {
    if (_selectedIndex == 0) return const AdminDashboardTab();
    if (_selectedIndex == 1) return const MenuManagementTab();
    if (_selectedIndex == 2) return const DailyMenuTab();
    if (_selectedIndex == 3) return const OrderManagementTab();
    return const CouponManagementTab();
  }

  // Show reset confirmation dialog
  void _showResetDialog(BuildContext context) {
    final lang = Provider.of<LanguageService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.isTurkish ? 'Verileri Sıfırla' : 'Reset Database'),
        content: Text(lang.isTurkish 
          ? 'Tüm menü verileri silinecek ve doğru dil ayarlarıyla (EN/TR) yeniden yüklenecek. Emin misiniz?' 
          : 'All menu data will be deleted and re-seeded with correct localizations (EN/TR). Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.isTurkish ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.isTurkish ? 'Sıfırlanıyor...' : 'Resetting...'))
              );
              await SeedService.forceSeed();
              if (mounted) {
                Provider.of<MenuService>(context, listen: false).fetchAllMeals();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.isTurkish ? 'Başarıyla Sıfırlandı!' : 'Successfully Reset!'),
                    backgroundColor: Colors.green,
                  )
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(lang.isTurkish ? 'Evet, Sıfırla' : 'Yes, Reset', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Menu management tab
class MenuManagementTab extends StatefulWidget {
  const MenuManagementTab({super.key});

  @override
  State<MenuManagementTab> createState() => _MenuManagementTabState();
}

class _MenuManagementTabState extends State<MenuManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuService>(context, listen: false).fetchAllMeals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<MenuService>(
      builder: (context, menuService, child) {
        final filteredMeals = menuService.meals.where((meal) {
          final query = _searchQuery.toLowerCase();
          return meal.name.toLowerCase().contains(query) || 
                 meal.description.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            // Header with add button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? IKASColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menu Items',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : IKASColors.textDark,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddMealDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: IKASColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? IKASColors.darkCard : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ],
              ),
            ),

            // Meals list with pull-to-refresh
            Expanded(
              child: menuService.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : menuService.meals.isEmpty
                      ? _buildEmptyState(context)
                      : filteredMeals.isEmpty
                          ? Center(
                              child: Text(
                                'No items found matching "$_searchQuery"',
                                style: GoogleFonts.poppins(
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await menuService.fetchAllMeals();
                              },
                              color: Theme.of(context).colorScheme.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredMeals.length,
                                itemBuilder: (context, index) {
                                  final meal = filteredMeals[index];
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 200 + (index * 30)),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildMealCard(context, meal, menuService),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }

  // Build empty state
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
                          Text(
                            'No items added yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _showAddMealDialog(context),
                            child: const Text('Add First Item'),
                          ),
        ],
      ),
    );
  }

  // Build meal card
  Widget _buildMealCard(BuildContext context, Meal meal, MenuService menuService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Meal image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (meal.isAvailable
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey)
                          .withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: meal.imageUrl.isNotEmpty
                      ? (meal.imageUrl.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: meal.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  _adminIconFallback(context, meal),
                            )
                          : Image.asset(
                              meal.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _adminIconFallback(context, meal),
                            ))
                      : _adminIconFallback(context, meal),
                ),
              ),
              const SizedBox(width: 12),
              
              // Meal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : IKASColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${meal.price.toStringAsFixed(2)} • ${meal.calories} cal • Stock: ${meal.stock}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditMealDialog(context, meal);
                  } else if (value == 'delete') {
                    _showDeleteMealDialog(context, meal, menuService);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminIconFallback(BuildContext context, Meal meal) {
    return Container(
      decoration: BoxDecoration(
        color: meal.isAvailable
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.restaurant,
        color: meal.isAvailable
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
        size: 26,
      ),
    );
  }

  // Show add meal dialog
  void _showAddMealDialog(BuildContext context) {
    _showMealDialog(context, null);
  }

  // Show edit meal dialog
  void _showEditMealDialog(BuildContext context, Meal meal) {
    _showMealDialog(context, meal);
  }

  // Show meal dialog (add or edit)
  void _showMealDialog(BuildContext context, Meal? meal) {
    final nameController = TextEditingController(text: meal?.name ?? '');
    final nameTrController = TextEditingController(text: meal?.nameTr ?? '');
    final descriptionController = TextEditingController(text: meal?.description ?? '');
    final descTrController = TextEditingController(text: meal?.descriptionTr ?? '');
    final priceController = TextEditingController(text: meal?.price.toStringAsFixed(2) ?? '');
    final caloriesController = TextEditingController(text: meal?.calories.toString() ?? '');
    final stockController = TextEditingController(text: meal?.stock.toString() ?? '');
    final proteinController = TextEditingController(
      text: meal?.nutrients['protein']?.toStringAsFixed(1) ?? '0',
    );
    final carbsController = TextEditingController(
      text: meal?.nutrients['carbs']?.toStringAsFixed(1) ?? '0',
    );
    final fatController = TextEditingController(
      text: meal?.nutrients['fat']?.toStringAsFixed(1) ?? '0',
    );
    final allergensController = TextEditingController(
      text: meal?.allergens.join(', ') ?? '',
    );
    final imageUrlController = TextEditingController(text: meal?.imageUrl ?? '');
    
    String selectedCategory = meal?.category ?? 'main';
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    // List of available local assets from pubspec
    final localAssets = [
      'assets/images/grilledchicken.jpeg',
      'assets/images/meatballs.jpeg',
      'assets/images/manti.jpeg',
      'assets/images/vegetablemeal.jpeg',
      'assets/images/lahmacun.jpeg',
      'assets/images/soup.jpeg',
      'assets/images/salad.jpeg',
      'assets/images/ricepudding.jpeg',
      'assets/images/ayran.jpeg',
      'assets/images/su.jpeg',
    ];

    Future<void> pickAndUpload(StateSetter setLocalState) async {
      try {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 75,
        );

        if (image == null) return;

        setLocalState(() => isUploading = true);

        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUri = 'data:image/jpeg;base64,$base64String';
        
        setLocalState(() {
          imageUrlController.text = dataUri;
          isUploading = false;
        });
        return;
      } catch (e) {
        setLocalState(() => isUploading = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? IKASColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        meal == null ? 'Add New Item' : 'Edit Item',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : IKASColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Info Section
                        _buildSectionTitle(context, 'Basic Information', Icons.info_outline),
                        TextField(
                          controller: nameController,
                          decoration: _inputDecoration(context, 'Product Name (EN) *', Icons.restaurant),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameTrController,
                          decoration: _inputDecoration(context, 'Ürün Adı (TR)', Icons.translate),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: _inputDecoration(context, 'Description (EN) *', Icons.description_outlined),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descTrController,
                          maxLines: 2,
                          decoration: _inputDecoration(context, 'Açıklama (TR)', Icons.description),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Pricing & Stock Section
                        _buildSectionTitle(context, 'Pricing & Inventory', Icons.inventory_2_outlined),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(context, 'Price (₺) *', Icons.payments_outlined),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(context, 'Stock *', Icons.inventory),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: caloriesController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(context, 'Calories *', Icons.local_fire_department_outlined),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: _inputDecoration(context, 'Category *', Icons.category_outlined),
                                items: const [
                                  DropdownMenuItem(value: 'main', child: Text('Main Course')),
                                  DropdownMenuItem(value: 'soup', child: Text('Soup')),
                                  DropdownMenuItem(value: 'salad', child: Text('Salad')),
                                  DropdownMenuItem(value: 'dessert', child: Text('Dessert')),
                                  DropdownMenuItem(value: 'drink', child: Text('Beverage')),
                                  DropdownMenuItem(value: 'diet', child: Text('Diet / Diyetik')),
                                ],
                                onChanged: (value) => setDialogState(() => selectedCategory = value!),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Nutritional Section
                        _buildSectionTitle(context, 'Nutritional Values (grams)', Icons.health_and_safety_outlined),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: proteinController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(context, 'Protein', null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: carbsController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(context, 'Carbs', null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: fatController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(context, 'Fat', null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: allergensController,
                          decoration: _inputDecoration(context, 'Allergens (comma separated)', Icons.warning_amber_rounded),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Image Section
                        _buildSectionTitle(context, 'Product Image', Icons.image_outlined),
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: isDark ? IKASColors.darkCard : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrlController.text.isNotEmpty
                                ? (imageUrlController.text.startsWith('http')
                                    ? Image.network(
                                        imageUrlController.text,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                                      )
                                    : Image.asset(
                                        imageUrlController.text,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                                      ))
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('No image selected', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isUploading ? null : () => pickAndUpload(setDialogState),
                                icon: isUploading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.upload_file),
                                label: Text(isUploading ? 'Uploading...' : 'Upload'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IKASColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Quick Choose'),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: GridView.builder(
                                          shrinkWrap: true,
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                          ),
                                          itemCount: localAssets.length,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () {
                                                setDialogState(() {
                                                  imageUrlController.text = localAssets[index];
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.asset(localAssets[index], fit: BoxFit.cover),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.collections_outlined),
                                label: const Text('Gallery'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: imageUrlController,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: _inputDecoration(context, 'Or Paste Image URL', Icons.link),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? IKASColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _saveMeal(
                                context,
                                meal,
                                nameController.text,
                                nameTrController.text,
                                descriptionController.text,
                                descTrController.text,
                                priceController.text,
                                caloriesController.text,
                                stockController.text,
                                selectedCategory,
                                proteinController.text,
                                carbsController.text,
                                fatController.text,
                                allergensController.text,
                                imageUrlController.text,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: IKASColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(
                              meal == null ? 'Add Item' : 'Save Changes',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Save meal (add or update)
  Future<void> _saveMeal(
    BuildContext context,
    Meal? meal,
    String name,
    String nameTr,
    String description,
    String descriptionTr,
    String priceStr,
    String caloriesStr,
    String stockStr,
    String category,
    String proteinStr,
    String carbsStr,
    String fatStr,
    String allergensStr,
    String imageUrl,
  ) async {
    // Fallbacks for missing localized texts
    if (name.trim().isEmpty && nameTr.trim().isNotEmpty) {
      name = nameTr.trim();
    }
    if (nameTr.trim().isEmpty && name.trim().isNotEmpty) {
      nameTr = name.trim();
    }
    if (description.trim().isEmpty && descriptionTr.trim().isNotEmpty) {
      description = descriptionTr.trim();
    }
    if (descriptionTr.trim().isEmpty && description.trim().isNotEmpty) {
      descriptionTr = description.trim();
    }

    // Validation
    if (name.trim().isEmpty || description.trim().isEmpty || priceStr.isEmpty || 
        caloriesStr.isEmpty || stockStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    final price = double.tryParse(priceStr);
    final calories = int.tryParse(caloriesStr);
    final stock = int.tryParse(stockStr);
    final protein = double.tryParse(proteinStr) ?? 0.0;
    final carbs = double.tryParse(carbsStr) ?? 0.0;
    final fat = double.tryParse(fatStr) ?? 0.0;

    if (price == null || calories == null || stock == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid numeric value'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }

    final allergens = allergensStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final menuService = Provider.of<MenuService>(context, listen: false);

    try {
      if (meal == null) {
        // Add new meal
        await menuService.addMeal(
          name: name,
          nameTr: nameTr,
          description: description,
          descriptionTr: descriptionTr,
          price: price,
          calories: calories,
          stock: stock,
          category: category,
          nutrients: {
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
          },
          allergens: allergens,
          imageUrl: imageUrl,
        );
      } else {
        // Update existing meal
        await menuService.updateMeal(
          mealId: meal.id,
          name: name,
          nameTr: nameTr,
          description: description,
          descriptionTr: descriptionTr,
          price: price,
          calories: calories,
          stock: stock,
          category: category,
          nutrients: {
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
          },
          allergens: allergens,
          imageUrl: imageUrl,
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(meal == null ? 'Item added' : 'Item updated'),
              backgroundColor: Colors.green,
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show delete meal dialog
  void _showDeleteMealDialog(BuildContext context, Meal meal, MenuService menuService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${meal.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await menuService.deleteMeal(meal.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  InputDecoration _inputDecoration(BuildContext context, String label, IconData? icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: IKASColors.primary, width: 2),
      ),
      filled: true,
      fillColor: isDark ? IKASColors.darkCard : Colors.grey.shade50,
      labelStyle: GoogleFonts.poppins(fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: IKASColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : IKASColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// Daily menu management tab
class DailyMenuTab extends StatefulWidget {
  const DailyMenuTab({super.key});

  @override
  State<DailyMenuTab> createState() => _DailyMenuTabState();
}

class _DailyMenuTabState extends State<DailyMenuTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuService>(context, listen: false).fetchAllMeals();
      Provider.of<MenuService>(context, listen: false).fetchTodayMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<MenuService>(
      builder: (context, menuService, child) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? IKASColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Daily Menu Management',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : IKASColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create today\'s menu',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showSetDailyMenuDialog(context, menuService),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IKASColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Today's menu items with pull-to-refresh
            Expanded(
              child: menuService.todayMeals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No menu created for today',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click the button above to create a menu',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? Colors.white30 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await menuService.fetchTodayMenu();
                      },
                      color: Theme.of(context).colorScheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: menuService.todayMeals.length,
                        itemBuilder: (context, index) {
                          final meal = menuService.todayMeals[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 200 + (index * 30)),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildTodayMealCard(context, meal),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayMealCard(BuildContext context, meal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: meal.imageUrl.isNotEmpty
                  ? (meal.imageUrl.startsWith('http')
                      ? Image.network(
                          meal.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _dailyMenuIconFallback(context),
                        )
                      : Image.asset(
                          meal.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _dailyMenuIconFallback(context),
                        ))
                  : _dailyMenuIconFallback(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : IKASColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₺${meal.price.toStringAsFixed(2)} • Stock: ${meal.stock}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyMenuIconFallback(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.restaurant, color: Colors.white, size: 26),
    );
  }

  void _showSetDailyMenuDialog(BuildContext context, MenuService menuService) {
    final selectedMeals = <String>{};
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? IKASColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Daily Menu',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : IKASColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select items to add to today\'s menu:',
                            style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                if (selectedMeals.length == menuService.meals.length) {
                                  selectedMeals.clear();
                                } else {
                                  selectedMeals.clear();
                                  selectedMeals.addAll(menuService.meals.map((m) => m.id));
                                }
                              });
                            },
                            child: Text(
                              selectedMeals.length == menuService.meals.length ? 'Deselect All' : 'Select All',
                              style: const TextStyle(color: IKASColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...menuService.meals.map((meal) {
                        final isSelected = selectedMeals.contains(meal.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? IKASColors.primary.withOpacity(0.1) : (isDark ? IKASColors.darkCard : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? IKASColors.primary : Colors.transparent),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  selectedMeals.remove(meal.id);
                                } else {
                                  selectedMeals.add(meal.id);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: meal.imageUrl.isNotEmpty
                                          ? (meal.imageUrl.startsWith('http')
                                              ? Image.network(meal.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.restaurant))
                                              : Image.asset(meal.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.restaurant)))
                                          : const Icon(Icons.restaurant),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal.name,
                                          style: GoogleFonts.poppins(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₺${meal.price.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            color: IKASColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: IKASColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          selectedMeals.add(meal.id);
                                        } else {
                                          selectedMeals.remove(meal.id);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? IKASColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedMeals.isEmpty
                                ? null
                                : () async {
                                    try {
                                      await menuService.setTodayMenu(selectedMeals.toList());
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Daily menu created successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: IKASColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text('Create Menu', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Order management tab
class OrderManagementTab extends StatelessWidget {
  const OrderManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrderManagementScreen();
  }
}

// ── Admin Dashboard Tab ───────────────────────────────────────────────
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderService>(context, listen: false).fetchAllOrders();
      Provider.of<MenuService>(context, listen: false).fetchAllMeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<OrderService, MenuService>(
      builder: (context, orderService, menuService, child) {
        if (orderService.isLoading && orderService.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: IKASColors.primary));
        }

        final orders = orderService.orders;
        double totalRevenue = 0;
        int totalItemsSold = 0;
        Map<String, int> mealSales = {};
        
        for (var order in orders) {
          totalRevenue += order.totalPrice;
          for(var item in order.items) {
            totalItemsSold += item.quantity;
            mealSales[item.meal.name] = (mealSales[item.meal.name] ?? 0) + item.quantity;
          }
        }

        String mostPopularItem = "Bulunamadı";
        if (mealSales.isNotEmpty) {
           var sorted = mealSales.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
           mostPopularItem = sorted.first.key;
        }

        final predictions = orderService.stockPredictions;
        final lowStockMeals = menuService.meals.where((m) => m.stock <= 5).toList();
        final criticalPredictions = menuService.meals.where((m) {
          final duration = predictions[m.id];
          return duration != null && duration.inMinutes < 60 && m.stock > 0;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            await orderService.fetchAllOrders();
            await menuService.fetchAllMeals();
          },
          color: IKASColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : IKASColors.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                
                if (lowStockMeals.isNotEmpty || criticalPredictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                          ? [Colors.red.withOpacity(0.3), Colors.orange.withOpacity(0.2)]
                          : [Colors.red.shade50, Colors.orange.shade50],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_rounded, color: Colors.red, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Akıllı Stok Analizi (Smart Stock Analysis)',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.red[300] : Colors.red[700],
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Combine both low stock and critical predictions for a unified restock list
                        ...[...lowStockMeals, ...criticalPredictions].toSet().map((m) {
                          final isCritical = criticalPredictions.contains(m);
                          final dur = isCritical ? predictions[m.id] : null;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : IKASColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        isCritical 
                                          ? 'Tahmin: ~${dur!.inMinutes} dk içinde bitebilir'
                                          : 'Kritik Stok: ${m.stock} adet kaldı',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: isCritical ? Colors.orange : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await menuService.quickRestock(m.id, 20);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${m.name} stok +20 eklendi'), backgroundColor: Colors.green)
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red)
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 14),
                                      label: const Text('20'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await menuService.quickRestock(m.id, 50);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${m.name} stok +50 eklendi'), backgroundColor: Colors.blue)
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red)
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 14),
                                      label: const Text('50'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                // Top Metrics Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 240,
                        child: _metricCard('Bugünkü Kazanç', '₺${totalRevenue.toStringAsFixed(2)}', Icons.attach_money_rounded, Colors.green, isDark),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 200,
                        child: _metricCard('Toplam Sipariş', '${orders.length}', Icons.shopping_bag_rounded, Colors.blue, isDark),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 220,
                        child: _metricCard('En Popüler Ürün', mostPopularItem, Icons.star_rounded, Colors.amber, isDark),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 200,
                        child: _metricCard('Satılan Ürün', '$totalItemsSold', Icons.fastfood_rounded, Colors.orange, isDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : IKASColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quick Actions
                // Quick Actions Wrap
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _actionButton(context, 'Refresh Data', Icons.refresh_rounded, IKASColors.primary, () => orderService.fetchAllOrders()),
                    _actionButton(context, 'Store Status', Icons.store_rounded, Colors.purple, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store opened/closed (Demo)')));
                    }),
                    if (menuService.meals.isEmpty)
                      _actionButton(context, 'Hızlı Kurulum (Setup Samples)', Icons.auto_awesome_rounded, Colors.orange, () async {
                        await menuService.seedDatabase();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Örnek ürünler ve görseller eklendi!'), backgroundColor: Colors.green),
                          );
                        }
                      }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : IKASColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Coupon Management Tab
class CouponManagementTab extends StatefulWidget {
  const CouponManagementTab({super.key});

  @override
  State<CouponManagementTab> createState() => _CouponManagementTabState();
}

class _CouponManagementTabState extends State<CouponManagementTab> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _percentageController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _codeController.dispose();
    _amountController.dispose();
    _percentageController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _createCoupon(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final coupon = Coupon(
        id: '',
        code: _codeController.text.trim().toUpperCase(),
        discountAmount: double.tryParse(_amountController.text) ?? 0.0,
        discountPercentage: (double.tryParse(_percentageController.text) ?? 0.0) / 100,
        description: _descController.text.trim(),
        expiryDate: _expiryDate,
        isActive: true,
      );
      try {
        await Provider.of<CouponService>(context, listen: false).createCoupon(coupon);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon created!')));
        _codeController.clear();
        _amountController.clear();
        _percentageController.clear();
        _descController.clear();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create New Coupon', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'Coupon Code (e.g. SUMMER20)'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(labelText: 'Flat Discount (₺)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _percentageController,
                            decoration: const InputDecoration(labelText: 'Percentage (%)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _createCoupon(context),
                        child: const Text('Create Coupon'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Existing Coupons', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Consumer<CouponService>(
            builder: (context, service, _) {
              if (service.coupons.isEmpty) return const Text('No coupons created yet.');
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: service.coupons.length,
                itemBuilder: (context, index) {
                  final c = service.coupons[index];
                  return Card(
                    child: ListTile(
                      title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${c.description}\nExpires: ${c.expiryDate.toString().substring(0, 10)}'),
                      trailing: Switch(
                        value: c.isActive,
                        onChanged: (val) => service.toggleCoupon(c.id, val),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
