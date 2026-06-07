import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/cart_service.dart';
import '../main.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../models/order.dart' as models;
import '../services/language_service.dart';
import '../services/coupon_service.dart';
import 'order_success_screen.dart';

// Order screen for creating and viewing orders
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isCreatingOrder = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    return Consumer<CartService>(
      builder: (context, cartService, child) {
        if (cartService.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_long, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(lang.createOrder, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
            body: _buildEmptyCart(context, lang),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.receipt_long, size: 20),
                ),
                const SizedBox(width: 12),
                Text(lang.createOrder, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline / Stepper Header
                _buildTimelineHeader(context, lang),
                const SizedBox(height: 24),

                // Order items compact list
                _buildOrderItemsList(context, cartService, lang),
                const SizedBox(height: 24),

                // Notes section
                _buildNotesSection(lang),
                const SizedBox(height: 32),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5)),
              ],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTotalSection(context, cartService, lang),
                const SizedBox(height: 16),
                _buildCreateOrderButton(context, cartService, lang),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineHeader(BuildContext context, LanguageService lang) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
        Expanded(child: Container(height: 2, color: Theme.of(context).colorScheme.primary.withOpacity(0.3))),
        Icon(Icons.radio_button_checked_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
        Expanded(child: Container(height: 2, color: Colors.grey.withOpacity(0.3))),
        Icon(Icons.flag_rounded, color: Colors.grey, size: 28),
      ],
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
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              lang.isTurkish ? 'Sipariş oluşturmak için sepete ürün ekleyin' : 'Add items to cart to create an order',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cleaned unused method

  Widget _buildNotesSection(LanguageService lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.notesOptional,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: lang.notesHint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: IKASColors.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
          ),
        ),
      ],
    );
  }


  Widget _buildOrderItemsList(BuildContext context, CartService cartService, LanguageService lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.orderDetails,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...cartService.items.map((item) => _buildOrderItemCard(context, item, lang)),
      ],
    );
  }

  // Build order item card with modern design
  Widget _buildOrderItemCard(BuildContext context, item, LanguageService lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Meal image or icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.meal.imageUrl.isNotEmpty
                  ? (item.meal.imageUrl.startsWith('http')
                      ? Image.network(
                          item.meal.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Colors.white, size: 24),
                        )
                      : (item.meal.imageUrl.startsWith('data:image')
                          ? Image.memory(
                              base64Decode(item.meal.imageUrl.split(',')[1]),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Colors.white, size: 24),
                            )
                          : Image.asset(
                              item.meal.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Colors.white, size: 24),
                            )))
                  : const Icon(Icons.restaurant, color: Colors.white, size: 24),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity} ${lang.isTurkish ? 'adet' : 'pcs'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x ₺${item.meal.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total price with badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
                      '₺${item.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Build total section for bottom navigation bar
  Widget _buildTotalSection(BuildContext context, CartService cartService, LanguageService lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        if (cartService.appliedCoupon != null) ...[
          _buildSummaryRow(lang.isTurkish ? 'Ara Toplam' : 'Subtotal', '₺${cartService.subtotal.toStringAsFixed(2)}', isDark, isStrikethrough: true),
          const SizedBox(height: 4),
          _buildSummaryRow(lang.isTurkish ? 'İndirim' : 'Discount', '-₺${cartService.discountAmount.toStringAsFixed(2)}', isDark, color: Colors.redAccent),
          const Divider(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.total, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '₺${cartService.finalPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: IKASColors.primary),
                ),
              ],
            ),
            if (cartService.appliedCoupon != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(cartService.appliedCoupon!.code, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isStrikethrough = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: color ?? (isDark ? Colors.white : Colors.black87),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }

  // Build create order button with modern design
  Widget _buildCreateOrderButton(BuildContext context, CartService cartService, LanguageService lang) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isCreatingOrder || cartService.hasUnavailableItems 
             ? [Colors.grey.shade400, Colors.grey.shade500] 
             : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!_isCreatingOrder && !cartService.hasUnavailableItems)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isCreatingOrder || cartService.hasUnavailableItems
              ? null
              : () => _createOrder(context, cartService, lang),
          child: Center(
            child: _isCreatingOrder
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        lang.isTurkish ? 'Siparişi Onayla' : 'Confirm Order',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }


  // Create order
  Future<void> _createOrder(BuildContext context, CartService cartService, LanguageService lang) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);

    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.pleaseSignIn),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingOrder = true;
    });

    final result = await orderService.createOrder(
      userId: authService.currentUserId,
      items: cartService.items,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      totalPrice: cartService.finalPrice,
      discountAmount: cartService.discountAmount,
    );


    // If order was created successfully and a coupon was applied, track its usage
    if (result['success'] == true && cartService.appliedCoupon != null) {
      final couponService = Provider.of<CouponService>(context, listen: false);
      await couponService.incrementUsage(
        cartService.appliedCoupon!.id,
        cartService.finalPrice,
      );
    }

    final error = result['success'] ? null : result['error'] as String?;
    final order = result['success'] ? result['order'] as models.Order : null;

    setState(() {
      _isCreatingOrder = false;
    });

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Clear cart on success
      cartService.clearCart();
      
      if (mounted) {
        // Clean up the tab's navigator first so we don't return to the cart
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Navigate to success screen on root navigator so it covers bottom nav
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(order: order!),
          ),
        );
      }
    }
  }
}

