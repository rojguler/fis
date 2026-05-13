import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../models/order.dart' as models;
import 'order_tracking_screen.dart';

class OrderTrackingListScreen extends StatelessWidget {
  const OrderTrackingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? IKASColors.darkBg : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          lang.isTurkish ? 'Sipariş Takibi' : 'Order Tracking',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? IKASColors.darkSurface : Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          return Consumer<OrderService>(
            builder: (context, orderService, _) {
              final orders = orderService.userOrders;

              if (orders.isEmpty) {
                return _buildEmptyState(context, lang, isDark);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(context, order, isDark, lang);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageService lang, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? IKASColors.darkCard : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: IKASColors.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            lang.isTurkish ? 'Henüz siparişin yok' : 'No orders yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : IKASColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.isTurkish ? 'Hemen lezzetli bir şeyler söyle!' : 'Go order something delicious!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: IKASColors.textMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, models.Order order, bool isDark, LanguageService lang) {
    final statusColor = _statusColor(order.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        order.status == models.OrderStatus.ready 
                          ? Icons.check_circle_rounded 
                          : (order.status == models.OrderStatus.preparing ? Icons.restaurant_rounded : Icons.receipt_long_rounded), 
                        color: statusColor, 
                        size: 24
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isDark ? Colors.white : IKASColors.textDark,
                            ),
                          ),
                          Text(
                            '${order.createdAt.day} ${lang.isTurkish ? _monthTr(order.createdAt.month) : _monthEn(order.createdAt.month)} · ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: IKASColors.textMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(order.status, lang),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} ${lang.isTurkish ? 'Ürün' : 'Items'}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: IKASColors.textMid,
                      ),
                    ),
                    Text(
                      '${order.totalPrice.toStringAsFixed(2)} ₺',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: IKASColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                      foregroundColor: isDark ? Colors.white : IKASColors.textDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      lang.isTurkish ? 'Detayları Gör' : 'View Details',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(models.OrderStatus status, LanguageService lang) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            lang.statusLabel(status).toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _monthTr(int m) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[m - 1];
  }

  String _monthEn(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  Color _statusColor(models.OrderStatus status) {
    switch (status) {
      case models.OrderStatus.pending:
        return Colors.orange;
      case models.OrderStatus.preparing:
        return Colors.blue;
      case models.OrderStatus.ready:
        return IKASColors.primary;
      case models.OrderStatus.completed:
        return Colors.grey;
      case models.OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
