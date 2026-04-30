import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../models/cart_item.dart';
import 'order_screen.dart';
import '../services/language_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../services/menu_service.dart';

// Cart screen for viewing and managing shopping cart
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_cart, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              lang.cart,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<CartService>(
            builder: (context, cartService, child) {
              if (cartService.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear Cart',
                  onPressed: () {
                    _showClearCartDialog(context, cartService, lang);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.isEmpty) {
            return _buildEmptyCart(context, lang);
          }

          return ListView(
            children: [
              // Cart items list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: cartService.items.length,
                itemBuilder: (context, index) {
                  final item = cartService.items[index];
                  return _buildCartItem(context, item, cartService, lang)
                    .animate(delay: (50 * index).ms)
                    .fade(duration: 300.ms)
                    .slideX(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
                },
              ),

              // Cross sell area
              _buildCrossSellSection(context, lang),

              // Total and checkout button
              _buildCheckoutSection(context, cartService, lang),
            ],
          );
        },
      ),
    );
  }

  // Build empty cart message with modern design
  Widget _buildEmptyCart(BuildContext context, LanguageService lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            lang.isTurkish ? 'Sepetiniz boş' : 'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              lang.isTurkish ? 'Sepetinize menüden ürünler ekleyin' : 'Add items from the menu to your cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.restaurant_menu),
            label: Text(lang.isTurkish ? 'Menüye Git' : 'Go to Menu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build cart item card with modern design
  Widget _buildCartItem(BuildContext context, CartItem item, CartService cartService, LanguageService lang) {
    return Dismissible(
      key: Key('cart_item_${item.meal.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        cartService.removeItem(item.meal.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark 
                ? [IKASColors.darkCard, IKASColors.darkCard.withOpacity(0.8)]
                : [const Color(0xFFFFF8E1), const Color(0xFFFFF8E1).withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Meal image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (item.isAvailable
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey)
                            .withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: item.meal.imageUrl.isNotEmpty
                        ? (item.meal.imageUrl.startsWith('http')
                            ? Image.network(
                                item.meal.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _cartIconFallback(context, item),
                              )
                            : (item.meal.imageUrl.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(item.meal.imageUrl.split(',')[1]),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _cartIconFallback(context, item),
                                  )
                                : Image.asset(
                                    item.meal.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _cartIconFallback(context, item),
                                  )))
                        : _cartIconFallback(context, item),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.meal.getLocalizedName(lang.isTurkish),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${lang.currency}${item.meal.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!item.isAvailable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning, size: 14, color: Colors.red[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    lang.outOfStock,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Quantity controls with modern design
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? IKASColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (item.quantity > 1) {
                              cartService.updateQuantity(item.meal.id, item.quantity - 1);
                            } else {
                              cartService.removeItem(item.meal.id);
                            }
                          },
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.remove,
                              size: 20,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (item.quantity < item.meal.stock && item.quantity < CartService.maxItemLimit) {
                              cartService.updateQuantity(item.meal.id, item.quantity + 1);
                            } else {
                              final msg = item.quantity >= CartService.maxItemLimit 
                                ? lang.maxLimitReached(CartService.maxItemLimit) 
                                : lang.maxStockReached(item.meal.stock);
                              ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                              );
                            }
                          },
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Remove button with modern design
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      cartService.removeItem(item.meal.id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red[600],
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildCrossSellSection(BuildContext context, LanguageService lang) {
    return Consumer<MenuService>(
      builder: (context, menuService, _) {
        final cartService = Provider.of<CartService>(context, listen: false);
        final cartItemIds = cartService.items.map((i) => i.meal.id).toList();
        
        // Find meals not in cart
        final suggestions = menuService.meals.where((m) => 
          !cartItemIds.contains(m.id) && (m.category == 'drink' || m.category == 'dessert')
        ).take(3).toList();

        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 24, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  lang.isTurkish ? 'Bunları da beğenebilirsiniz:' : 'You might also like:',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: suggestions.length,
                  itemBuilder: (context, i) {
                    final meal = suggestions[i];
                    return GestureDetector(
                      onTap: () {
                         HapticFeedback.lightImpact();
                         cartService.addItem(meal);
                      },
                      child: Container(
                        width: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? IKASColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 50, height: 50,
                                child: meal.imageUrl.startsWith('http') 
                                    ? Image.network(meal.imageUrl, fit: BoxFit.cover) 
                                    : (meal.imageUrl.startsWith('data:image') 
                                        ? Image.memory(base64Decode(meal.imageUrl.split(',')[1]), fit: BoxFit.cover)
                                        : Image.asset(meal.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey))),
                              )
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(meal.getLocalizedName(lang.isTurkish), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12)),
                                  Text('+ ₺${meal.price.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build checkout section with realistic receipt design
  Widget _buildCheckoutSection(BuildContext context, CartService cartService, LanguageService lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Realistic Receipt Summary section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Receipt Header
                Center(
                  child: Text(
                    'IKAS SUPER MARKET',
                    style: GoogleFonts.vt323(
                      fontSize: 24,
                      letterSpacing: 2,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _dashedLine(isDark),
                const SizedBox(height: 16),

                // ── Nutrition Summary ──
                Text(
                  lang.nutritionSummary,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : IKASColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _nutriTag(Icons.local_fire_department_rounded, '${cartService.totalCalories} kcal', Colors.orange),
                    _nutriTag(Icons.fitness_center_rounded, '${cartService.totalProtein.toStringAsFixed(1)}g Pro', Colors.blue),
                    _nutriTag(Icons.spa_rounded, '${cartService.totalCarbs.toStringAsFixed(1)}g Carb', Colors.green),
                    _nutriTag(Icons.water_drop_rounded, '${cartService.totalFat.toStringAsFixed(1)}g Fat', Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                const SizedBox(height: 10),
                // ── Price Summary ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cartService.itemCount} ${lang.items}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${lang.currency}${cartService.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Warning if cart has unavailable items
          if (cartService.hasUnavailableItems)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.15),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[700],
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.cartHasUnavailableItems,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Checkout button with gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: cartService.hasUnavailableItems
                      ? Colors.grey.withOpacity(0.2)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: cartService.hasUnavailableItems
                  ? null
                  : () {
                      _navigateToCheckout(context);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    lang.createOrder,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Info text with icon
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                lang.payAtCafeteria,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigate to checkout/order screen
  void _navigateToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderScreen(),
      ),
    );
  }

  // Show clear cart dialog with modern design
  void _showClearCartDialog(BuildContext context, CartService cartService, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              lang.clearCart,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          lang.confirmClearCart,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              lang.cancel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
              ),
            ),
            child: TextButton(
              onPressed: () {
                cartService.clearCart();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang.cartCleared),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                foregroundColor: Colors.white,
              ),
              child: Text(
                lang.isTurkish ? 'Temizle' : 'Clear',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartIconFallback(BuildContext context, CartItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.isAvailable
              ? [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ]
              : [Colors.grey[400]!, Colors.grey[300]!],
        ),
      ),
      child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
    );
  }

  // Helper widget for Nutrition Tags
  Widget _nutriTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedLine(bool isDark) {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : (isDark ? Colors.white30 : Colors.grey.shade400),
            height: 1,
          ),
        ),
      ),
    );
  }
}

