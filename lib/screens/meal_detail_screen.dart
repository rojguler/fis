import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../main.dart';
import '../services/menu_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../services/order_service.dart';
import '../utils/toast_utils.dart';
import 'cart_screen.dart';
import '../services/language_service.dart';
import '../services/stock_prediction_service.dart';

// Enhanced detailed view of a single meal with share, and related meals
class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? IKASColors.darkBg : IKASColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                elevation: 0,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? IKASColors.darkBg : Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                            onPressed: () => _shareMeal(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'meal-${meal.id}',
                        child: meal.imageUrl.isNotEmpty
                            ? (meal.imageUrl.startsWith('http')
                                ? CachedNetworkImage(imageUrl: meal.imageUrl, fit: BoxFit.cover)
                                : (meal.imageUrl.startsWith('data:image')
                                    ? Image.memory(base64Decode(meal.imageUrl.split(',')[1]), fit: BoxFit.cover)
                                    : Image.asset(meal.imageUrl, fit: BoxFit.cover)))
                            : Container(color: Colors.grey.shade200),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black45, Colors.transparent, Colors.black87],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? IKASColors.darkBg : IKASColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meal.getLocalizedName(lang.isTurkish),
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                      color: isDark ? Colors.white : IKASColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                                            const SizedBox(width: 4),
                                            Text('4.8', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.orange.shade800)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Consumer<ReviewService>(
                                        builder: (context, reviewService, _) {
                                          final reviews = reviewService.getReviewsForMeal(meal.id);
                                          return Text('(${reviews.length} ${lang.reviews})', 
                                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500));
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: 24),
                        _buildPriceCard(context).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildQuickStats(context).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                        const SizedBox(height: 24),
                        _buildDescriptionCard(context).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        _buildNutritionCard(context).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        if (meal.allergens.isNotEmpty) 
                          _buildAllergensCard(context).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                        const SizedBox(height: 32),
                        _MealReviewsSection(meal: meal).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 32),
                        _buildRelatedMeals(context).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildStickyBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.7) 
                : Colors.white.withOpacity(0.85),
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: _buildAddToCartButton(context),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 500.ms, curve: Curves.easeOutBack);
  }

  void _shareMeal(BuildContext context) {
    final lang = Provider.of<LanguageService>(context, listen: false);
    final shareText = '${meal.getLocalizedName(lang.isTurkish)} - ₺${meal.price.toStringAsFixed(2)}\n'
        '${meal.calories} calories\n'
        '${meal.getLocalizedDescription(lang.isTurkish)}';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(lang.shareMeal, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(context, Icons.copy_rounded, lang.isTurkish ? 'Kopyala' : 'Copy', () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  ToastUtils.showTopToast(context, lang.isTurkish ? 'Kopyalandı!' : 'Copied!');
                  Navigator.pop(context);
                }),
                _buildShareOption(context, Icons.message_rounded, 'SMS', () => Navigator.pop(context)),
                _buildShareOption(context, Icons.alternate_email_rounded, 'Email', () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: IKASColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: IKASColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? IKASColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.price,
                    style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₺${meal.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w900, color: IKASColors.primary, letterSpacing: -1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: meal.isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: meal.isAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(meal.isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded, color: meal.isAvailable ? Colors.green : Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      meal.isAvailable 
                          ? (lang.isTurkish ? 'Stokta (${meal.stock})' : 'In Stock (${meal.stock})')
                          : lang.outOfStock,
                      style: GoogleFonts.poppins(color: meal.isAvailable ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (meal.isAvailable) ...[
          const SizedBox(height: 16),
          Consumer<OrderService>(
            builder: (context, orderService, _) {
              final prediction = orderService.stockPredictions[meal.id];
              if (prediction == null) return const SizedBox.shrink();
              final isTurkish = lang.isTurkish;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_graph_rounded, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        StockPredictionService.getPredictionText(prediction, isTurkish),
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context, icon: Icons.local_fire_department_rounded, value: '${meal.calories}', label: lang.kcal, color: Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(context, icon: Icons.fitness_center_rounded, value: '${meal.nutrients['protein']?.toStringAsFixed(1) ?? '0'}g', label: lang.proteinG, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(context, icon: Icons.timer_rounded, value: '15-20', label: lang.isTurkish ? 'Dakika' : 'Min', color: Colors.purple),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String value, required String label, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : IKASColors.textDark)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: IKASColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(lang.description, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : IKASColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meal.getLocalizedDescription(lang.isTurkish),
            style: GoogleFonts.poppins(fontSize: 14, height: 1.6, color: isDark ? Colors.white70 : IKASColors.textMid),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: IKASColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(lang.nutritionFacts, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : IKASColors.textDark)),
            ],
          ),
          const SizedBox(height: 20),
          ...meal.nutrients.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _getNutrientIcon(entry.key),
                  const SizedBox(width: 12),
                  Text(entry.key.toUpperCase(), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const Spacer(),
                  Text('${entry.value.toStringAsFixed(1)}g', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: IKASColors.primary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _getNutrientIcon(String nutrient) {
    IconData icon;
    Color color;
    switch (nutrient.toLowerCase()) {
      case 'protein': icon = Icons.fitness_center; color = Colors.blue; break;
      case 'carbs': icon = Icons.energy_savings_leaf; color = Colors.orange; break;
      case 'fat': icon = Icons.water_drop; color = Colors.red; break;
      default: icon = Icons.circle; color = Colors.grey;
    }
    return Icon(icon, color: color, size: 18);
  }

  Widget _buildAllergensCard(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Text(lang.allergens, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.orange[800])),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meal.allergens.map((allergen) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(allergen, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange[900])),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedMeals(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final menuService = Provider.of<MenuService>(context);
    final relatedMeals = menuService.meals.where((m) => m.category == meal.category && m.id != meal.id).take(3).toList();

    if (relatedMeals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.relatedMeals, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: relatedMeals.length,
            itemBuilder: (context, index) {
              final m = relatedMeals[index];
              return GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: m))),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? IKASColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: m.imageUrl.isNotEmpty
                              ? (m.imageUrl.startsWith('http')
                                  ? CachedNetworkImage(imageUrl: m.imageUrl, fit: BoxFit.cover, width: double.infinity)
                                  : (m.imageUrl.startsWith('data:image')
                                      ? Image.memory(base64Decode(m.imageUrl.split(',')[1]), fit: BoxFit.cover, width: double.infinity)
                                      : Image.asset(m.imageUrl, fit: BoxFit.cover, width: double.infinity)))
                              : Container(color: Colors.grey[200]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.getLocalizedName(lang.isTurkish), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('₺${m.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: IKASColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final lang = Provider.of<LanguageService>(context);
    final quantity = cartService.getQuantity(meal.id);
    final isInCart = quantity > 0;
    final canAdd = meal.isAvailable && meal.stock > 0;

    if (!meal.isAvailable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cancel_rounded, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(lang.outOfStock, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        ]),
      );
    }

    if (isInCart) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: IKASColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: IKASColors.primary, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.shopping_cart_rounded, color: IKASColors.primary, size: 20),
                const SizedBox(width: 12),
                Text('($quantity)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: IKASColors.primary)),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (quantity > 1) cartService.updateQuantity(meal.id, quantity - 1);
                    else cartService.removeItem(meal.id);
                  },
                  icon: Icon(Icons.remove_circle_rounded, color: IKASColors.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: IKASColors.primary, borderRadius: BorderRadius.circular(12)),
                  child: Text('$quantity', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                IconButton(
                  onPressed: () {
                    if (quantity < meal.stock && quantity < CartService.maxItemLimit) {
                      HapticFeedback.lightImpact();
                      cartService.updateQuantity(meal.id, quantity + 1);
                    } else {
                      ToastUtils.showTopToast(context, 'Maksimum stok: ${meal.stock}');
                    }
                  },
                  icon: Icon(Icons.add_circle_rounded, color: IKASColors.primary),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: _SlideToAddButton(
        label: canAdd ? (lang.isTurkish ? 'Kaydırarak Sepete Ekle' : 'Slide to Add') : lang.outOfStock,
        color: canAdd ? IKASColors.primary : Colors.grey,
        onSlideCompleted: canAdd ? () {
          HapticFeedback.heavyImpact();
          cartService.addItem(meal);
          ToastUtils.showTopToast(
            context, 
            '${meal.getLocalizedName(lang.isTurkish)} ${lang.isTurkish ? 'sepete eklendi' : 'added to cart'}',
            actionLabel: lang.isTurkish ? 'Sepete Git' : 'Go to Cart',
            onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          );
        } : () {},
      ),
    );
  }
}

class _SlideToAddButton extends StatefulWidget {
  final VoidCallback onSlideCompleted;
  final String label;
  final Color color;

  const _SlideToAddButton({
    required this.onSlideCompleted,
    required this.label,
    required this.color,
  });

  @override
  _SlideToAddButtonState createState() => _SlideToAddButtonState();
}

class _SlideToAddButtonState extends State<_SlideToAddButton> {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = 60;
        final double threshold = width * 0.7;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              Center(
                child: Shimmer.fromColors(
                  baseColor: widget.color,
                  highlightColor: Colors.white,
                  child: Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: _isCompleted || _dragPosition == 0 ? const Duration(milliseconds: 300) : Duration.zero,
                curve: Curves.easeOutBack,
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > width - height) {
                         _dragPosition = width - height;
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompleted) return;
                    if (_dragPosition > threshold) {
                      setState(() {
                        _dragPosition = width - height;
                        _isCompleted = true;
                      });
                      widget.onSlideCompleted();
                      // Reset after a delay
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _dragPosition = 0;
                            _isCompleted = false;
                          });
                        }
                      });
                    } else {
                      setState(() {
                        _dragPosition = 0;
                      });
                    }
                  },
                  child: Container(
                    width: height,
                    height: height,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3)),
                      ]
                    ),
                    child: Icon(
                      _isCompleted ? Icons.check_rounded : Icons.keyboard_double_arrow_right_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MealReviewsSection extends StatefulWidget {
  final Meal meal;

  const _MealReviewsSection({required this.meal});

  @override
  State<_MealReviewsSection> createState() => _MealReviewsSectionState();
}

class _MealReviewsSectionState extends State<_MealReviewsSection> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;
  bool _canReview = false;
  bool _isCheckingReview = true;
  String _lastUserId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewService>(context, listen: false)
          .fetchReviewsForMeal(widget.meal.id);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context);
    if (authService.currentUserId != _lastUserId || _lastUserId.isEmpty) {
      _lastUserId = authService.currentUserId;
      _checkCanReview(authService.isAuthenticated, authService.currentUserId);
    }
  }

  Future<void> _checkCanReview(bool isAuthenticated, String userId) async {
    if (!isAuthenticated) {
      if (mounted) {
        setState(() {
          _canReview = false;
          _isCheckingReview = false;
        });
      }
      return;
    }
    
    setState(() {
      _isCheckingReview = true;
    });

    final orderService = Provider.of<OrderService>(context, listen: false);
    final canReview = await orderService.hasCompletedOrderForMeal(userId, widget.meal.id);
    
    if (mounted) {
      setState(() {
        _canReview = canReview;
        _isCheckingReview = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      final lang = Provider.of<LanguageService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.pleaseComment)),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated) {
      final lang = Provider.of<LanguageService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.pleaseLogin)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Provider.of<ReviewService>(context, listen: false).addReview(
        mealId: widget.meal.id,
        userId: authService.currentUserId,
        userName: authService.currentUserName.isNotEmpty == true ? authService.currentUserName : (authService.currentUserEmail.isNotEmpty ? authService.currentUserEmail : 'Anonymous'),
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      _commentController.clear();
      setState(() {
        _rating = 5.0;
      });
      
      if (mounted) {
      final lang = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.reviewDone), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageService>(context);

    return Consumer2<ReviewService, AuthService>(
      builder: (context, reviewService, authService, child) {
        final reviews = reviewService.getReviewsForMeal(widget.meal.id);
        final averageRating = reviewService.getAverageRating(widget.meal.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  lang.reviews,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : IKASColors.textDark,
                  ),
                ),
                if (reviews.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: IKASColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${averageRating.toStringAsFixed(1)} ★ (${reviews.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: IKASColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            
            // ── Add Review Form ──
            if (!authService.isAuthenticated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? IKASColors.darkCard : Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.mustSignInToReview,
                        style: GoogleFonts.poppins(color: isDark ? Colors.white70 : Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isCheckingReview)
              const Center(child: CircularProgressIndicator())
            else if (!_canReview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? IKASColors.darkCard : Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.orderToReview,
                        style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.amber.shade200 : Colors.amber.shade800),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? IKASColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.rateThisMeal,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : IKASColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? IKASColors.darkSurface : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => _rating = index + 1.0),
                            child: Icon(
                              index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: index < _rating ? Colors.amber : Colors.grey.shade400,
                              size: 34,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: lang.shareThoughts,
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        filled: true,
                        fillColor: isDark ? IKASColors.darkSurface : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: IKASColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSubmitting 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(lang.submitReview, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 30),

            // ── Review List ──
            if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isDark ? IKASColors.darkCard : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      lang.noReviewsYet,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : IKASColors.textDark,
                      ),
                    ),
                    Text(
                      lang.beFirstToReview,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: IKASColors.textMid,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (context, _) => Divider(color: isDark ? Colors.white10 : Colors.black12, height: 32),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: IKASColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                            style: GoogleFonts.poppins(color: IKASColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Review Content
                      Expanded(
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Expanded(
                                   child: Text(
                                     review.userName,
                                     style: GoogleFonts.poppins(
                                       fontWeight: FontWeight.bold,
                                       fontSize: 15,
                                       color: isDark ? Colors.white : Colors.black87,
                                     ),
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                                 Row(
                                   children: List.generate(5, (starIndex) {
                                     return Icon(
                                       starIndex < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                       size: 14,
                                       color: Colors.amber,
                                     );
                                   }),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 4),
                             Text(
                               '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                               style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                             ),
                             const SizedBox(height: 8),
                             Text(
                               review.comment,
                               style: GoogleFonts.poppins(
                                 fontSize: 13,
                                 height: 1.4,
                                 color: isDark ? Colors.white70 : Colors.grey.shade800,
                               ),
                             ),
                           ],
                         ),
                       ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

