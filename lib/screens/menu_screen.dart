import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/menu_service.dart';
import '../widgets/shimmer_loading.dart';

import '../models/meal.dart';
import '../services/search_history_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'meal_detail_screen.dart';
import '../services/language_service.dart';
import '../services/cart_service.dart';
import '../utils/toast_utils.dart';
import 'package:flutter/services.dart';

// Enhanced menu screen with search, sorting, and advanced filtering
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'name'; // name, price, calories, protein
  bool _sortAscending = true;

  // Advanced Filters
  double _minProtein = 0;
  double _maxCarbs = 100;
  final List<String> _excludedAllergens = [];
  bool _isHighProteinOnly = false;
  bool _isLowCarbOnly = false;
  bool _isVeganOnly = false;
  bool _isGlutenFreeOnly = false;

  LanguageService get lang => Provider.of<LanguageService>(context, listen: false);

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

  // Filter and sort meals
  List<Meal> _filterAndSortMeals(List<Meal> meals) {
    var filtered = meals;

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((meal) => meal.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((meal) {
        return meal.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            meal.nameTr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            meal.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            meal.descriptionTr.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Advanced Nutritional Filters
    if (_isHighProteinOnly) {
      filtered = filtered.where((m) => (m.nutrients['protein'] ?? 0) >= 20).toList();
    } else if (_minProtein > 0) {
      filtered = filtered.where((m) => (m.nutrients['protein'] ?? 0) >= _minProtein).toList();
    }

    if (_isLowCarbOnly) {
      filtered = filtered.where((m) => (m.nutrients['carbs'] ?? 100) <= 30).toList();
    } else if (_maxCarbs < 100) {
      filtered = filtered.where((m) => (m.nutrients['carbs'] ?? 0) <= _maxCarbs).toList();
    }

    if (_isVeganOnly) {
      filtered = filtered.where((m) => m.isVegan).toList();
    }

    if (_isGlutenFreeOnly) {
      filtered = filtered.where((m) => m.isGlutenFree).toList();
    }

    // Allergen Filter
    if (_excludedAllergens.isNotEmpty) {
      filtered = filtered.where((m) {
        // If the meal contains any of the excluded allergens, filter it out
        return !m.allergens.any((a) => _excludedAllergens.contains(a));
      }).toList();
    }

    // Sort meals
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'calories':
          comparison = a.calories.compareTo(b.calories);
          break;
        case 'protein':
          final aProtein = a.nutrients['protein'] ?? 0.0;
          final bProtein = b.nutrients['protein'] ?? 0.0;
          comparison = aProtein.compareTo(bProtein);
          break;
        case 'name':
        default:
          comparison = a.name.compareTo(b.name);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<MenuService>(
        builder: (context, menuService, child) {
          final filteredMeals = _filterAndSortMeals(menuService.meals);

          return RefreshIndicator(
            onRefresh: () async {
              await Provider.of<MenuService>(context, listen: false).fetchAllMeals();
            },
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
            slivers: [
              // Modern gradient app bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    lang.allProducts,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Filter button (Prominent)
                  _buildFilterAction(context, isDark),
                  // Sort button
                  _buildSortAction(context, isDark),
                  const SizedBox(width: 8),
                ],
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? IKASColors.darkCard : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: lang.searchHint,
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          Provider.of<SearchHistoryService>(context, listen: false)
                              .addQuery(value);
                        }
                      },
                    ),
                  ),
                ),
              ),

              // ── Search History Chips ──
              Consumer<SearchHistoryService>(
                builder: (context, historyService, child) {
                  if (historyService.history.isEmpty || _searchQuery.isNotEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.recentSearches,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              TextButton(
                                onPressed: () => historyService.clearAll(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  lang.clearAll,
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: historyService.history.map((query) {
                              return ActionChip(
                                label: Text(query, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onPressed: () {
                                  _searchController.text = query;
                                  setState(() {
                                    _searchQuery = query;
                                  });
                                  historyService.addQuery(query); // bump to top
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Category filter chips
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? IKASColors.darkSurface : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                    height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                        _buildCategoryChip('all', lang.catAll, Icons.restaurant_menu),
                        _buildCategoryChip('main', lang.catMain, Icons.restaurant),
                        _buildCategoryChip('soup', lang.catSoup, Icons.soup_kitchen),
                        _buildCategoryChip('salad', lang.catSalad, Icons.eco),
                        _buildCategoryChip('dessert', lang.catDessert, Icons.cake),
                        _buildCategoryChip('drink', lang.catDrink, Icons.local_drink),
                        _buildCategoryChip('diet', lang.catDiet, Icons.monitor_weight),
                      ],
                    ),
                  ),
                ),
              ),

              // Results count and sort info
              if (filteredMeals.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${filteredMeals.length} ${lang.itemsCount}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (_sortBy != 'name')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${lang.sortedBy} $_sortBy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Loading indicator
              if (menuService.isLoading && menuService.meals.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: MealCardShimmer(),
                    ),
                    childCount: 5,
                  ),
                ),

              // Empty state
              if (!menuService.isLoading && filteredMeals.isEmpty)
                SliverFillRemaining(
                  child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _searchQuery.isNotEmpty || _selectedCategory != 'all'
                                ? Icons.search_off
                                : Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                        ),
                        const SizedBox(height: 24),
                            Text(
                          _searchQuery.isNotEmpty || _selectedCategory != 'all'
                              ? 'No meals found'
                              : 'No meals available',
                              style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != 'all'
                              ? 'Try adjusting your search or filters'
                              : 'Check back later for new meals',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedCategory = 'all';
                              });
                            },
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Meals list
              if (!menuService.isLoading && filteredMeals.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildMealCard(context, filteredMeals[index])
                            .animate(delay: (50 * index).ms)
                            .fade(duration: 300.ms)
                            .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
                      },
                      childCount: filteredMeals.length,
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

  Widget _buildFilterAction(BuildContext context, bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _showFilterDialog,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isFilterActive ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: _isFilterActive ? IKASColors.primary : Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                lang.filters,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isFilterActive ? IKASColors.primary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortAction(BuildContext context, bool isDark) {
    return IconButton(
      icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 22),
      onPressed: _showSortDialog,
    );
  }

  bool get _isFilterActive => 
    _minProtein > 0 || _maxCarbs < 100 || _excludedAllergens.isNotEmpty || 
    _isHighProteinOnly || _isLowCarbOnly || _isVeganOnly || _isGlutenFreeOnly;

  // Show filter dialog
  void _showFilterDialog() {
    final allAllergens = Provider.of<MenuService>(context, listen: false)
        .meals
        .expand((m) => m.allergens)
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.filters,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _minProtein = 0;
                          _maxCarbs = 100;
                          _excludedAllergens.clear();
                          _isHighProteinOnly = false;
                          _isLowCarbOnly = false;
                          _isVeganOnly = false;
                          _isGlutenFreeOnly = false;
                        });
                      },
                      child: Text(lang.resetFilters),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text(lang.isTurkish ? 'Hızlı Seçimler' : 'Quick Presets', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterPresetCard(
                        label: lang.highProtein,
                        isSelected: _isHighProteinOnly,
                        onTap: () {
                          setModalState(() => _isHighProteinOnly = !_isHighProteinOnly);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterPresetCard(
                        label: lang.lowCarb,
                        isSelected: _isLowCarbOnly,
                        onTap: () {
                          setModalState(() => _isLowCarbOnly = !_isLowCarbOnly);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterPresetCard(
                        label: 'Vegan',
                        isSelected: _isVeganOnly,
                        onTap: () {
                          setModalState(() => _isVeganOnly = !_isVeganOnly);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterPresetCard(
                        label: lang.isTurkish ? 'Glütensiz' : 'Gluten-Free',
                        isSelected: _isGlutenFreeOnly,
                        onTap: () {
                          setModalState(() => _isGlutenFreeOnly = !_isGlutenFreeOnly);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
  
                // Protein Slider
                if (!_isHighProteinOnly) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang.proteinAmount, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      Text('${_minProtein.round()}g+', style: GoogleFonts.poppins(color: IKASColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _minProtein,
                    min: 0,
                    max: 50,
                    divisions: 10,
                    activeColor: IKASColors.primary,
                    onChanged: (val) {
                      setModalState(() => _minProtein = val);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
  
                // Carb Slider
                if (!_isLowCarbOnly) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang.carbAmount, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      Text('< ${_maxCarbs.round()}g', style: GoogleFonts.poppins(color: IKASColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _maxCarbs,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    activeColor: IKASColors.primary,
                    onChanged: (val) {
                      setModalState(() => _maxCarbs = val);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
  
                // Allergens
                if (allAllergens.isNotEmpty) ...[
                  Text(lang.allergensToExclude, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allAllergens.map((allergen) {
                      final isExcluded = _excludedAllergens.contains(allergen);
                      return FilterChip(
                        label: Text(allergen),
                        selected: isExcluded,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              _excludedAllergens.add(allergen);
                            } else {
                              _excludedAllergens.remove(allergen);
                            }
                          });
                        },
                        selectedColor: Colors.red.withOpacity(0.12),
                        checkmarkColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: isExcluded ? Colors.red.withOpacity(0.5) : Colors.grey.shade300),
                        labelStyle: GoogleFonts.poppins(
                          color: isExcluded ? Colors.red : null,
                          fontSize: 12,
                          fontWeight: isExcluded ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
  
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Apply to parent
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: IKASColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: IKASColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(lang.applyFilters, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show sort bottom sheet
  void _showSortDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? IKASColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                lang.isTurkish ? 'Sıralama Seçenekleri' : 'Sort Options',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : IKASColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              _buildSortItem('name', Icons.sort_by_alpha_rounded, lang.isTurkish ? 'İsim' : 'Name'),
              _buildSortItem('price', Icons.attach_money_rounded, lang.isTurkish ? 'Fiyat' : 'Price'),
              _buildSortItem('calories', Icons.local_fire_department_rounded, lang.isTurkish ? 'Kalori' : 'Calories'),
              _buildSortItem('protein', Icons.fitness_center_rounded, lang.isTurkish ? 'Protein' : 'Protein'),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.isTurkish ? 'Artan Sıralama' : 'Sort Ascending',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : IKASColors.textMid,
                    ),
                  ),
                  Switch(
                    value: _sortAscending,
                    activeColor: IKASColors.primary,
                    onChanged: (val) {
                      setState(() => _sortAscending = val);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortItem(String value, IconData icon, String label) {
    final isSelected = _sortBy == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? IKASColors.primary.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? IKASColors.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? IKASColors.primary : (isDark ? IKASColors.darkCard : Colors.grey[100]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected 
                    ? IKASColors.primary 
                    : (isDark ? Colors.white : IKASColors.textDark),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: IKASColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // Build category chip
  Widget _buildCategoryChip(String category, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]),
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        selectedColor: Theme.of(context).colorScheme.primary,
        checkmarkColor: Colors.white,
        backgroundColor: isDark ? IKASColors.darkCard : Colors.grey[100],
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: isSelected ? 4 : 0,
      ),
    );
  }

  // Build meal card
  Widget _buildMealCard(BuildContext context, Meal meal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageService>(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        decoration: BoxDecoration(
          color: isDark ? IKASColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Row(
            children: [
              // Image Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Hero(
                  tag: 'meal-${meal.id}',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: meal.imageUrl.isNotEmpty
                          ? (meal.imageUrl.startsWith('http')
                              ? CachedNetworkImage(imageUrl: meal.imageUrl, fit: BoxFit.cover)
                              : (meal.imageUrl.startsWith('data:image')
                                  ? Image.memory(base64Decode(meal.imageUrl.split(',')[1]), fit: BoxFit.cover)
                                  : Image.asset(meal.imageUrl, fit: BoxFit.cover)))
                          : _mealIconFallback(context, meal),
                    ),
                  ),
                ),
              ),
              
              // Info Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: IKASColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              meal.category.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: IKASColors.primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (!meal.isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                lang.outOfStock,
                                style: GoogleFonts.poppins(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal.getLocalizedName(lang.isTurkish),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : IKASColors.textDark,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meal.calories} kcal • ${meal.nutrients['protein']}g protein',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : IKASColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₺${meal.price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: IKASColors.primary,
                            ),
                          ),
                          Consumer<CartService>(
                            builder: (context, cart, _) => GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                cart.addItem(meal);
                                ToastUtils.showTopToast(context, lang.itemAddedCart);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: IKASColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: IKASColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, curve: Curves.easeOutQuad),
    );
  }

  // Fallback icon when image is not available
  Widget _mealIconFallback(BuildContext context, Meal meal) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: meal.isAvailable
              ? [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ]
              : [Colors.grey[400]!, Colors.grey[300]!],
        ),
      ),
      child: const Icon(Icons.restaurant, color: Colors.white, size: 30),
    );
  }
}

class _FilterPresetCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPresetCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
