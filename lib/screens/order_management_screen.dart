import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/order_service.dart';
import '../models/order.dart' as models;
import '../services/language_service.dart';

// Order management screen for admin to view and manage orders
class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start real-time stream for all orders
      Provider.of<OrderService>(context, listen: false).listenToAllOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<OrderService>(
      builder: (context, orderService, child) {
        if (orderService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingOrders = orderService.orders.where((o) => o.status == models.OrderStatus.pending).toList();
        final activeOrders = orderService.orders.where((o) => o.status == models.OrderStatus.preparing || o.status == models.OrderStatus.ready).toList();
        final pastOrders = orderService.orders.where((o) => o.status == models.OrderStatus.completed || o.status == models.OrderStatus.cancelled).toList();

        return Column(
          children: [
            // Header with TabBar
            Container(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.isTurkish ? 'Sipariş Yönetimi' : 'Order Management',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : IKASColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: isDark ? Colors.white70 : IKASColors.textDark),
                          tooltip: 'Real-time sync active',
                          onPressed: () {
                            // Stream is already live; this just restarts it
                            orderService.listenToAllOrders();
                          },
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: IKASColors.primary,
                    unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[600],
                    indicatorColor: IKASColors.primary,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
                    tabs: [
                      Tab(text: '${lang.isTurkish ? 'Bekleyen' : 'Pending'} (${pendingOrders.length})'),
                      Tab(text: '${lang.isTurkish ? 'Aktif' : 'Active'} (${activeOrders.length})'),
                      Tab(text: '${lang.isTurkish ? 'Geçmiş' : 'Past'} (${pastOrders.length})'),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(pendingOrders, isDark, orderService, lang),
                  _buildOrderList(activeOrders, isDark, orderService, lang),
                  _buildOrderList(pastOrders, isDark, orderService, lang),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderList(List<models.Order> orders, bool isDark, OrderService orderService, LanguageService lang) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              lang.isTurkish ? 'Bu kategoride sipariş yok' : 'No orders in this category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => orderService.fetchAllOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(context, order, orderService, lang);
        },
      ),
    );
  }

  // Build order card
  Widget _buildOrderCard(BuildContext context, models.Order order, OrderService orderService, LanguageService lang) {
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
          // Order header
          Wrap(
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
                    '${lang.isTurkish ? 'Sipariş' : 'Order'} #${order.id.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : IKASColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.createdAt.month}/${order.createdAt.day}/${order.createdAt.year} ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(order.status).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  lang.statusLabel(order.status),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(order.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Order items
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.meal.getLocalizedName(lang.isTurkish)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : IKASColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '₺${item.totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: IKASColors.primary,
                      ),
                    ),
                  ],
                ),
              )),
          
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 18, color: isDark ? Colors.white54 : Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          Divider(height: 32, color: isDark ? Colors.white12 : Colors.black12),
          
          // Total and actions
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              Text(
                '${lang.total}: ₺${order.totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: IKASColors.primary,
                ),
              ),
              // Status update buttons
              if (order.status == models.OrderStatus.pending)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _updateOrderStatus(context, order, models.OrderStatus.cancelled, orderService, lang),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(lang.isTurkish ? 'İptal' : 'Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => _updateOrderStatus(context, order, models.OrderStatus.preparing, orderService, lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(lang.isTurkish ? 'Hazırla' : 'Prepare'),
                    ),
                  ],
                )
              else if (order.status == models.OrderStatus.preparing)
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(context, order, models.OrderStatus.ready, orderService, lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IKASColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(lang.isTurkish ? 'Hazır' : 'Ready'),
                )
              else if (order.status == models.OrderStatus.ready)
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(context, order, models.OrderStatus.completed, orderService, lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(lang.isTurkish ? 'Tamamla' : 'Complete'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Get status color
  Color _getStatusColor(models.OrderStatus status) {
    switch (status) {
      case models.OrderStatus.pending:
        return Colors.orange;
      case models.OrderStatus.preparing:
        return Colors.blue;
      case models.OrderStatus.ready:
        return Colors.green;
      case models.OrderStatus.completed:
        return Colors.grey;
      case models.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // Update order status
  Future<void> _updateOrderStatus(
    BuildContext context,
    models.Order order,
    models.OrderStatus newStatus,
    OrderService orderService,
    LanguageService lang,
  ) async {
    final error = await orderService.updateOrderStatus(order.id, newStatus);
    
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.isTurkish ? 'Sipariş durumu güncellendi' : 'Order status updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

