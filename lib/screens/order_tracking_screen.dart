import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../models/order.dart' as models;
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/menu_service.dart';
import 'cart_screen.dart';
import '../services/language_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../widgets/review_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

/// Real-time visual order progress tracker.
/// Listens directly to Firestore so status updates from admin
/// are reflected instantly — no polling needed.
class OrderTrackingScreen extends StatelessWidget {
  final models.Order order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMock = order.id.isEmpty || order.id.startsWith('mock_');
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isMock
          ? _buildBody(context, isDark, order, lang)
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.id)
                  .snapshots(),
              builder: (context, snapshot) {
                // Use the latest Firestore data if available,
                // otherwise fall back to the passed-in order
                models.Order liveOrder = order;

                final auth = Provider.of<AuthService>(context, listen: false);
                if (snapshot.hasData && snapshot.data!.exists) {
                  try {
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    
                    // Security check: If not admin and not the owner, deny access
                    if (!auth.isAdmin && data['userId'] != auth.currentUserId) {
                      return Scaffold(
                        body: Center(
                          child: Text(lang.isTurkish ? 'Erişim Engellendi' : 'Access Denied'),
                        ),
                      );
                    }

                    final menuService =
                        Provider.of<MenuService>(context, listen: false);

                    final itemsData = List<Map<String, dynamic>>.from(
                        data['items'] ?? []);
                    final items = <CartItem>[];
                    for (var itemData in itemsData) {
                      final mealId = itemData['mealId'] as String;
                      final quantity = itemData['quantity'] as int;
                      try {
                        final meal = menuService.meals
                            .firstWhere((m) => m.id == mealId);
                        items.add(CartItem(meal: meal, quantity: quantity));
                      } catch (_) {}
                    }
                    if (items.isNotEmpty) {
                      liveOrder =
                          models.Order.fromFirestore(data, order.id, items);
                    }
                  } catch (e) {
                    debugPrint('Error parsing live order: $e');
                  }
                }

                return _buildBody(context, isDark, liveOrder, lang);
              },
            ),
    );
  }

  Widget _buildBody(
      BuildContext context, bool isDark, models.Order liveOrder, LanguageService lang) {
    return CustomScrollView(
      slivers: [
        // ── App bar ──
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              lang.orderTracking,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    IKASColors.primaryDark,
                    IKASColors.primary,
                    IKASColors.accent
                  ],
                ),
              ),
                  child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              liveOrder.displayNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${liveOrder.items.length} ${lang.items.toLowerCase()} · ₺${liveOrder.totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Live indicator ──
                _LiveBadge(isMock: liveOrder.id.startsWith('mock_order_')),
                const SizedBox(height: 16),

                // ── Kuyruk Pozisyonu + Tahmini Süre ──
                if (liveOrder.status == models.OrderStatus.pending ||
                    liveOrder.status == models.OrderStatus.preparing)
                  _QueueInfoCard(order: liveOrder, lang: lang),
                const SizedBox(height: 16),

                // ── Status badge ──
                _StatusBanner(order: liveOrder, lang: lang).animate().fadeIn().slideX(begin: 0.1),
                const SizedBox(height: 28),

                // ── Pickup Code (Visible when Ready) ──
                if (liveOrder.status == models.OrderStatus.ready)
                  _PickupCodeSection(orderId: liveOrder.id, isDark: isDark, lang: lang),
                
                const SizedBox(height: 28),

                // ── Timeline ──
                Text(lang.orderProgress,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.white : IKASColors.textDark)).animate().fadeIn(),
                const SizedBox(height: 16),
                _OrderTimeline(status: liveOrder.status, lang: lang).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 28),

                // ── Items ──
                Text(lang.items,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? Colors.white : IKASColors.textDark)).animate().fadeIn(),
                const SizedBox(height: 12),
                ...liveOrder.items.asMap().entries.map((entry) {
                  return _ItemRow(item: entry.value, isDark: isDark, lang: lang)
                      .animate(delay: (100 * entry.key).ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1);
                }),

                const SizedBox(height: 20),
                // ── Total ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: IKASColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang.total,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(
                          '₺${liveOrder.totalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),

                if (liveOrder.notes != null &&
                    liveOrder.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_rounded,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(liveOrder.notes!,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.amber.shade800)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),

                // ── Review Button (Visible if Completed) ──
                if (liveOrder.status == models.OrderStatus.completed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        showDialog(
                          context: context,
                          builder: (context) => ReviewDialog(order: liveOrder),
                        );
                      },
                      icon: const Icon(Icons.star_rate_rounded),
                      label: Text(lang.isTurkish ? 'Siparişi Değerlendir' : 'Leave a Review'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                  const SizedBox(height: 16),
                ],

                // ── Reorder Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final cart = Provider.of<CartService>(context,
                          listen: false);
                      cart.clearCart();
                      for (final item in liveOrder.items) {
                        cart.addItem(item.meal, quantity: item.quantity);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(lang.itemsAddedToCart)),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CartScreen()),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(lang.reorder),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: IKASColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Kuyruk Bilgisi Kartı ──────────────────────────────────────────────────────
class _QueueInfoCard extends StatelessWidget {
  final models.Order order;
  final LanguageService lang;
  
  const _QueueInfoCard({required this.order, required this.lang});

  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final position = orderService.getQueuePosition(order.id);
    final waitMinutes = order.estimatedMinutes ?? orderService.getEstimatedWaitMinutes(order.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IKASColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Pozisyon
          Expanded(
            child: Column(
              children: [
                Text(
                  lang.isTurkish ? 'Sıranız' : 'Queue Position',
                  style: GoogleFonts.poppins(fontSize: 11, color: IKASColors.textMid),
                ),
                Text(
                  '#$position',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: IKASColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
          // Süre
          Expanded(
            child: Column(
              children: [
                Text(
                  lang.isTurkish ? 'Tahmini Süre' : 'Est. Wait',
                  style: GoogleFonts.poppins(fontSize: 11, color: IKASColors.textMid),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '$waitMinutes ${lang.isTurkish ? 'dk' : 'min'}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : IKASColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live indicator badge ───────────────────────────────────────────────────────
class _LiveBadge extends StatefulWidget {
  final bool isMock;
  const _LiveBadge({required this.isMock});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    if (widget.isMock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Colors.grey, size: 12),
            const SizedBox(width: 6),
            Text(lang.demoMode,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.green.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green
                    .withOpacity(_pulse.value),
              ),
            ),
            const SizedBox(width: 6),
            Text(lang.liveUpdates,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700)),
          ],
        ),
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final models.Order order;
  final LanguageService lang;
  const _StatusBanner({required this.order, required this.lang});

  @override
  Widget build(BuildContext context) {
    final (color, icon, message) = _info(order.status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.statusLabel(order.status),
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
                Text(message,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: color.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _info(models.OrderStatus s) {
    switch (s) {
      case models.OrderStatus.pending:
        return (Colors.orange, Icons.hourglass_top_rounded, lang.statusPendingMsg);
      case models.OrderStatus.preparing:
        return (Colors.blue, Icons.restaurant_rounded, lang.statusPreparingMsg);
      case models.OrderStatus.ready:
        return (IKASColors.primary, Icons.check_circle_rounded, lang.statusReadyMsg);
      case models.OrderStatus.completed:
        return (Colors.grey, Icons.done_all_rounded, lang.statusCompletedMsg);
      case models.OrderStatus.cancelled:
        return (Colors.red, Icons.cancel_rounded, lang.statusCancelledMsg);
    }
  }
}

// ── Timeline ─────────────────────────────────────────────────────────────────
class _OrderTimeline extends StatelessWidget {
  final models.OrderStatus status;
  final LanguageService lang;
  const _OrderTimeline({required this.status, required this.lang});

  List<(models.OrderStatus, IconData, String)> get _steps => [
    (models.OrderStatus.pending, Icons.receipt_long_rounded, lang.statusLabel(models.OrderStatus.pending)),
    (models.OrderStatus.preparing, Icons.restaurant_rounded, lang.statusLabel(models.OrderStatus.preparing)),
    (models.OrderStatus.ready, Icons.check_circle_rounded, lang.statusLabel(models.OrderStatus.ready)),
    (models.OrderStatus.completed, Icons.done_all_rounded, lang.statusLabel(models.OrderStatus.completed)),
  ];

  int get _currentStep =>
      _isCancelled ? -1 : _steps.indexWhere((s) => s.$1 == status);

  bool get _isCancelled => status == models.OrderStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.cancel_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Text(lang.statusLabel(models.OrderStatus.cancelled),
              style: GoogleFonts.poppins(
                  color: Colors.red, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Column(
      children: List.generate(_steps.length, (i) {
        final (_, icon, label) = _steps[i];
        final isCompleted = i <= _currentStep;
        final isActive = i == _currentStep;
        final isLast = i == _steps.length - 1;

        final textColor = isCompleted
            ? (isDark ? Colors.white : IKASColors.textDark)
            : Colors.grey.shade400;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle + line
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? IKASColors.primary
                        : (isDark
                            ? IKASColors.darkCard
                            : Colors.grey.shade100),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: IKASColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Icon(icon,
                      color: isCompleted
                          ? Colors.white
                          : Colors.grey.shade400,
                      size: 20),
                ),
                if (!isLast)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 2,
                    height: 32,
                    color: isCompleted && i < _currentStep
                        ? IKASColors.primary
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Label
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: textColor)),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: IKASColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(lang.isTurkish ? 'Şu anki' : 'Current',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: IKASColors.primary)),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Order item row ───────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final dynamic item;
  final bool isDark;
  final LanguageService lang;
  const _ItemRow({required this.item, required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: IKASColors.chipBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: IKASColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.meal.getLocalizedName(lang.isTurkish),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : IKASColors.textDark)),
          ),
          Text('x${item.quantity}',
              style:
                  GoogleFonts.poppins(fontSize: 12, color: IKASColors.textMid)),
          const SizedBox(width: 12),
          Text('₺${item.totalPrice.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: IKASColors.primary)),
        ],
      ),
    );
  }
}

// ── Pickup Code Section ────────────────────────────────────────────────────────
class _PickupCodeSection extends StatelessWidget {
  final String orderId;
  final bool isDark;
  final LanguageService lang;
  
  const _PickupCodeSection({required this.orderId, required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    final pickupCode = orderId.substring(orderId.length - 4).toUpperCase();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [Colors.blue.shade900, Colors.indigo.shade900] 
            : [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, color: isDark ? Colors.blue.shade300 : Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Text(
                lang.isTurkish ? 'Teslimat Kodu' : 'Pickup Code',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.blue.shade100 : Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Text(
              pickupCode,
              style: GoogleFonts.shareTechMono(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: isDark ? Colors.white : Colors.blue.shade900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.isTurkish 
              ? 'Yemeğin hazır! Bu kodu görevliye göstererek teslim alabilirsin.' 
              : 'Your food is ready! Show this code to the staff to pickup.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
