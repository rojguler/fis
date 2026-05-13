import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import 'order_screen.dart';
import '../services/language_service.dart';
import '../services/coupon_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../services/menu_service.dart';

// Cart screen for viewing and managing shopping cart
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: IKASColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_cart, size: 20, color: IKASColors.primary),
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
              if (cartService.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                tooltip: lang.isTurkish ? 'Sepeti Temizle' : 'Clear Cart',
                onPressed: () => _showClearCartDialog(context, cartService, lang),
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

          return Column(
            children: [
              Expanded(
                child: ListView(
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
                    
                    const SizedBox(height: 120), // More space for bottom section
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.isEmpty) return const SizedBox.shrink();
          return _buildCheckoutSection(context, cartService, lang);
        },
      ),
    );
  }

  // Build empty cart message
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: Text(lang.isTurkish ? 'Menüye Git' : 'Go to Menu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  // Build cart item card
  Widget _buildCartItem(BuildContext context, CartItem item, CartService cartService, LanguageService lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60, height: 60,
              child: item.meal.imageUrl.startsWith('http') 
                  ? Image.network(item.meal.imageUrl, fit: BoxFit.cover) 
                  : (item.meal.imageUrl.startsWith('data:image') 
                      ? Image.memory(base64Decode(item.meal.imageUrl.split(',')[1]), fit: BoxFit.cover)
                      : Image.asset(item.meal.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey))),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.meal.getLocalizedName(lang.isTurkish), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('₺${item.meal.price.toStringAsFixed(2)}', style: TextStyle(color: IKASColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => cartService.updateQuantity(item.meal.id, item.quantity - 1),
              ),
              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => cartService.updateQuantity(item.meal.id, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build checkout section
  Widget _buildCheckoutSection(BuildContext context, CartService cartService, LanguageService lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price breakdown card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Coupon Input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: InputDecoration(
                          hintText: lang.isTurkish ? 'Kupon Kodu' : 'Coupon Code',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final service = Provider.of<CouponService>(context, listen: false);
                        final coupon = await service.validateCoupon(_couponController.text.trim());
                        if (coupon != null) {
                          cartService.applyCoupon(coupon);
                          _couponController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.isTurkish ? 'Geçersiz kupon' : 'Invalid coupon'), backgroundColor: Colors.red));
                        }
                      },
                      child: Text(lang.isTurkish ? 'Uygula' : 'Apply'),
                    ),
                  ],
                ),
                if (cartService.appliedCoupon != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text('${cartService.appliedCoupon!.code} applied', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close, size: 14), onPressed: () => cartService.removeCoupon()),
                    ],
                  ),
                ],
                const Divider(height: 32),
                _buildPriceRow(lang.isTurkish ? 'Ara Toplam' : 'Subtotal', '₺${cartService.subtotal.toStringAsFixed(2)}', isDark),
                if (cartService.appliedCoupon != null) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(lang.isTurkish ? 'İndirim' : 'Discount', '-₺${cartService.discountAmount.toStringAsFixed(2)}', isDark, color: Colors.redAccent),
                ],
                const SizedBox(height: 12),
                _buildPriceRow(lang.total, '₺${cartService.finalPrice.toStringAsFixed(2)}', isDark, isBold: true, fontSize: 18, color: IKASColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cartService.hasUnavailableItems ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: IKASColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(lang.createOrder, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isDark, {bool isBold = false, double fontSize = 14, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white70 : Colors.black87)),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.bold, color: color ?? (isDark ? Colors.white : Colors.black87))),
      ],
    );
  }

  Widget _buildCrossSellSection(BuildContext context, LanguageService lang) {
    return Consumer<MenuService>(
      builder: (context, menuService, _) {
        final cartService = Provider.of<CartService>(context, listen: false);
        final suggestions = menuService.meals.where((m) => !cartService.isInCart(m.id) && (m.category == 'drink' || m.category == 'dessert')).take(3).toList();
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 100,
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(lang.isTurkish ? 'Bunları da beğenebilirsiniz:' : 'You might also like:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: suggestions.length,
                  itemBuilder: (context, i) {
                    final meal = suggestions[i];
                    return ActionChip(
                      label: Text('${meal.getLocalizedName(lang.isTurkish)} (+₺${meal.price})'),
                      onPressed: () => cartService.addItem(meal),
                      backgroundColor: IKASColors.primary.withOpacity(0.05),
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

  void _showClearCartDialog(BuildContext context, CartService cartService, LanguageService lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.clearCart),
        content: Text(lang.confirmClearCart),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.cancel)),
          TextButton(onPressed: () { cartService.clearCart(); Navigator.pop(context); }, child: Text(lang.isTurkish ? 'Temizle' : 'Clear')),
        ],
      ),
    );
  }
}
