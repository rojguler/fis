import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as models;
import '../models/cart_item.dart';
import '../models/meal.dart';
import '../services/menu_service.dart';
import '../services/email_service.dart';
import '../main.dart'; // To access globalMessengerKey and IKASColors
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/stock_prediction_service.dart';

// Service for managing orders with real-time synchronization
class OrderService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MenuService _menuService;

  List<models.Order> _orders = [];
  bool _isLoading = false;

  // Real-time stream subscriptions
  StreamSubscription<QuerySnapshot>? _allOrdersSubscription;
  StreamSubscription<QuerySnapshot>? _userOrdersSubscription;
  String? _currentUserId; // track which user we're listening for

  OrderService(this._menuService);

  List<models.Order> get orders => _orders;
  bool get isLoading => _isLoading;

  /// Get stock predictions for all meals
  Map<String, Duration> get stockPredictions {
    return StockPredictionService.predictTimeRemaining(_orders, _menuService.meals);
  }

  // ─── Helper: check if Firebase is properly configured ───────────────────────
  bool get _isFirebaseConfigured {
    final key = _firestore.app.options.apiKey;
    return !key.contains('Dummy') && !key.contains('Replace') && key.length >= 20;
  }

  // ─── Parse Firestore snapshot to Order list ──────────────────────────────────
  List<models.Order> _parseSnapshot(QuerySnapshot snapshot) {
    final result = <models.Order>[];
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final itemsData = List<Map<String, dynamic>>.from(data['items'] ?? []);

      final items = <CartItem>[];
      for (var itemData in itemsData) {
        final mealId = itemData['mealId'] as String;
        final quantity = itemData['quantity'] as int;
        try {
          final meal = _menuService.meals.firstWhere((m) => m.id == mealId);
          items.add(CartItem(meal: meal, quantity: quantity));
        } catch (e) {
          debugPrint('Meal not found in cache: $mealId');
        }
      }

      if (items.isNotEmpty) {
        result.add(models.Order.fromFirestore(data, doc.id, items));
      }
    }
    return result;
  }

  // ─── Listen to ALL orders in real-time (admin) ───────────────────────────────
  void listenToAllOrders() {
    if (!_isFirebaseConfigured) return;

    // Cancel existing subscription if any
    _allOrdersSubscription?.cancel();
    _userOrdersSubscription?.cancel();
    _currentUserId = null;

    _isLoading = true;
    notifyListeners();

    _allOrdersSubscription = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final newOrders = _parseSnapshot(snapshot);
            
            // Check for completely new pending orders to notify Admin
            if (_orders.isNotEmpty) {
              for (var newOrder in newOrders) {
                if (newOrder.status == models.OrderStatus.pending) {
                  // If it's a new ID that we didn't have before
                  if (!_orders.any((o) => o.id == newOrder.id)) {
                    final context = globalMessengerKey.currentContext;
                    if (context != null) {
                      final lang = Provider.of<LanguageService>(context, listen: false);
                      globalMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.adminNewOrder,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                              ),
                              Text(
                                lang.adminNewOrderSub,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.orange.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 6),
                          margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
                        ),
                      );
                    }
                  }
                }
              }
            }

            _orders = newOrders;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error in all-orders stream: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // ─── Listen to a specific user's orders in real-time (user) ─────────────────
  void listenToUserOrders(String userId) {
    if (!_isFirebaseConfigured) return;

    // Don't re-subscribe if already listening to this user
    if (_currentUserId == userId && _userOrdersSubscription != null) return;

    _allOrdersSubscription?.cancel();
    _userOrdersSubscription?.cancel();
    _currentUserId = userId;

    _isLoading = true;
    notifyListeners();

    _userOrdersSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final newOrders = _parseSnapshot(snapshot);
            
            // Check for status changes to trigger a notification
            if (_orders.isNotEmpty) {
              for (var newOrder in newOrders) {
                try {
                  final oldOrder = _orders.firstWhere((o) => o.id == newOrder.id);
                  if (oldOrder.status != newOrder.status && newOrder.status != models.OrderStatus.pending) {
                    final context = globalMessengerKey.currentContext;
                    if (context != null) {
                      final lang = Provider.of<LanguageService>(context, listen: false);
                      String statusText = '';
                      switch (newOrder.status) {
                        case models.OrderStatus.preparing:
                          statusText = lang.orderPreparing;
                          break;
                        case models.OrderStatus.ready:
                          statusText = lang.orderReady;
                          break;
                        case models.OrderStatus.completed:
                          statusText = lang.orderCompleted;
                          break;
                        case models.OrderStatus.cancelled:
                          statusText = lang.orderCancelled;
                          break;
                        default:
                          statusText = lang.orderUpdated;
                      }
                      globalMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            '${lang.orderUpdatePrefix}$statusText',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: IKASColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 4),
                          margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
                        ),
                      );
                    }
                  }
                } catch (_) {} // Order might be new, ignore
              }
            }

            _orders = newOrders;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error in user-orders stream: $e');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // ─── Stop listening (call on logout) ─────────────────────────────────────────
  void stopListening() {
    _allOrdersSubscription?.cancel();
    _allOrdersSubscription = null;
    _userOrdersSubscription?.cancel();
    _userOrdersSubscription = null;
    _currentUserId = null;
    _orders = [];
    notifyListeners();
  }

  // ─── Fetch all orders (admin, one-time fallback / mock) ──────────────────────
  Future<void> fetchAllOrders() async {
    if (!_isFirebaseConfigured) {
      // Mock mode: already in memory
      await Future.delayed(const Duration(milliseconds: 300));
      notifyListeners();
      return;
    }
    // If the stream is already active, just notify (data is fresh)
    if (_allOrdersSubscription != null) {
      notifyListeners();
      return;
    }
    listenToAllOrders();
  }

  // ─── Fetch user orders (one-time fallback / mock) ─────────────────────────────
  Future<void> fetchUserOrders(String userId) async {
    if (!_isFirebaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 300));
      notifyListeners();
      return;
    }
    listenToUserOrders(userId);
  }

  // ─── Create order from cart items ─────────────────────────────────────────────
  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required List<CartItem> items,
    String? notes,
  }) async {
    if (items.isEmpty) return {'success': false, 'error': 'Cart is empty'};

    // Check stock availability
    for (var item in items) {
      final latestMeal = _menuService.meals.firstWhere(
        (meal) => meal.id == item.meal.id,
        orElse: () => item.meal,
      );
      if (!latestMeal.isAvailable || item.quantity > latestMeal.stock) {
        return {'success': false, 'error': '${item.meal.name} is no longer in stock'};
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final totalPrice = items.fold(0.0, (sum, item) => sum + item.totalPrice);

      // ── Generate a short order number (daily counter) ──────────────────────
      final today = DateTime.now();
      final dayKey =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
      int orderNumber = 1001; // start from 1001
      try {
        final counterRef = _firestore.collection('counters').doc('orderNumber_$dayKey');
        await _firestore.runTransaction((tx) async {
          final snap = await tx.get(counterRef);
          if (snap.exists) {
            orderNumber = (snap.data()!['value'] as num).toInt() + 1;
          }
          tx.set(counterRef, {'value': orderNumber, 'date': dayKey});
        });
      } catch (_) {
        // Fallback: use timestamp suffix
        orderNumber = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
      }

      final orderData = {
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
        'totalPrice': totalPrice,
        'createdAt': Timestamp.now(),
        'status': models.OrderStatus.pending.toString().split('.').last,
        'notes': notes,
        'orderNumber': orderNumber,
        'estimatedMinutes': null,
      };

      models.Order? createdOrder;

      if (!_isFirebaseConfigured) {
        await Future.delayed(const Duration(seconds: 1));
        createdOrder = models.Order(
          id: 'mock_order_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          items: items.toList(),
          totalPrice: totalPrice,
          createdAt: DateTime.now(),
          status: models.OrderStatus.pending,
          notes: notes,
          orderNumber: orderNumber,
        );
        _orders.insert(0, createdOrder);
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'order': createdOrder};
      }

      // Save to Firestore
      final docRef = await _firestore.collection('orders').add(orderData);
      
      createdOrder = models.Order(
        id: docRef.id,
        userId: userId,
        items: items.toList(),
        totalPrice: totalPrice,
        createdAt: DateTime.now(),
        status: models.OrderStatus.pending,
        notes: notes,
        orderNumber: orderNumber,
      );

      // Update stock
      for (var item in items) {
        await _firestore.collection('meals').doc(item.meal.id).update({
          'stock': FieldValue.increment(-item.quantity),
        });
      }

      _isLoading = false;
      notifyListeners();
      return {'success': true, 'order': createdOrder};
    } catch (e) {
      debugPrint('Error creating order: $e');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': 'Error creating order: $e'};
    }
  }

  // ─── Cancel order (only if pending) ──────────────────────────────────────────
  Future<String?> cancelOrder(String orderId) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);
      if (!order.canCancel) return 'This order cannot be cancelled';

      if (!_isFirebaseConfigured) {
        await Future.delayed(const Duration(milliseconds: 500));
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index >= 0) {
          _orders[index] = models.Order(
            id: order.id,
            userId: order.userId,
            items: order.items,
            totalPrice: order.totalPrice,
            createdAt: order.createdAt,
            status: models.OrderStatus.cancelled,
            notes: order.notes,
          );
        }
        notifyListeners();
        return null;
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': models.OrderStatus.cancelled.toString().split('.').last,
      });

      // Restore stock
      for (var item in order.items) {
        await _firestore.collection('meals').doc(item.meal.id).update({
          'stock': FieldValue.increment(item.quantity),
        });
      }

      // Stream handles the UI update automatically
      return null;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return 'Error cancelling order: $e';
    }
  }

  // ─── Update order status (admin) ──────────────────────────────────────────────
  Future<String?> updateOrderStatus(String orderId, models.OrderStatus status) async {
    try {
      final order = _orders.firstWhere((o) => o.id == orderId);

      if (!_isFirebaseConfigured) {
        await Future.delayed(const Duration(milliseconds: 500));
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index >= 0) {
          _orders[index] = models.Order(
            id: order.id,
            userId: order.userId,
            items: order.items,
            totalPrice: order.totalPrice,
            createdAt: order.createdAt,
            status: status,
            notes: order.notes,
          );
        }
        notifyListeners();
        return null;
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
      });

      // Siparişin sahibine e-posta gönder (asenkron olarak)
      try {
        final userDoc = await _firestore.collection('users').doc(order.userId).get();
        if (userDoc.exists && userDoc.data()!.containsKey('email')) {
          final userEmail = userDoc.data()!['email'] as String;
          if (userEmail.isNotEmpty) {
            
            // Basitçe durumu Türkçeye çevir
            String statusT = status.toString().split('.').last;
            if (status == models.OrderStatus.preparing) statusT = "Hazırlanıyor 👨‍🍳";
            else if (status == models.OrderStatus.ready) statusT = "Hazır! Afiyet Olsun 🍽️";
            else if (status == models.OrderStatus.completed) statusT = "Tamamlandı ✅";
            else if (status == models.OrderStatus.cancelled) statusT = "İptal Edildi ❌";

            EmailService.sendOrderStatusEmail(
              userEmail: userEmail,
              orderId: order.id,
              newStatus: status.toString(),
              statusText: statusT,
            ).catchError((e) => debugPrint('Sipariş mail hatası: \$e'));
          }
        }
      } catch (e) {
        debugPrint('Kullanıcı maili çekilirken hata: \$e');
      }

      // Restore stock if admin cancels
      if (status == models.OrderStatus.cancelled &&
          order.status != models.OrderStatus.cancelled) {
        for (var item in order.items) {
          await _firestore.collection('meals').doc(item.meal.id).update({
            'stock': FieldValue.increment(item.quantity),
          });
        }
      }

      // Stream will push the update to all listeners automatically
      return null;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return 'Error updating order status: $e';
    }
  }

  // ─── Check if user has a completed order containing a meal ───────────────────
  Future<bool> hasCompletedOrderForMeal(String userId, String mealId) async {
    try {
      if (!_isFirebaseConfigured) {
        for (var order in _orders) {
          if (order.userId == userId &&
              order.status == models.OrderStatus.completed) {
            for (var item in order.items) {
              if (item.meal.id == mealId) return true;
            }
          }
        }
        return false;
      }

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where(
            'status',
            isEqualTo:
                models.OrderStatus.completed.toString().split('.').last,
          )
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itemsData =
            List<Map<String, dynamic>>.from(data['items'] ?? []);
        for (var itemData in itemsData) {
          if (itemData['mealId'] == mealId) return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking completed orders: $e');
      return false;
    }
  }

  // ─── Queue position for a given order (how many pending/preparing orders are ahead) ──
  int getQueuePosition(String orderId) {
    final activeStatuses = {models.OrderStatus.pending, models.OrderStatus.preparing};
    final activeOrders = _orders
        .where((o) => activeStatuses.contains(o.status))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final idx = activeOrders.indexWhere((o) => o.id == orderId);
    return idx < 0 ? 0 : idx + 1;
  }

  /// Rough estimated wait: ~5 minutes per active order ahead in queue.
  int getEstimatedWaitMinutes(String orderId) {
    final pos = getQueuePosition(orderId);
    return pos * 5;
  }

  // ─── Admin: set estimated minutes on a specific order ───────────────────────
  Future<void> setEstimatedMinutes(String orderId, int minutes) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'estimatedMinutes': minutes,
      });
    } catch (e) {
      debugPrint('Error setting estimated minutes: $e');
    }
  }

  // ─── Admin statistics ────────────────────────────────────────────────────────
  Map<String, dynamic> getDailyStats() {
    final today = DateTime.now();
    final todayOrders = _orders.where((o) {
      return o.createdAt.year == today.year &&
          o.createdAt.month == today.month &&
          o.createdAt.day == today.day;
    }).toList();

    final revenue = todayOrders
        .where((o) => o.status != models.OrderStatus.cancelled)
        .fold(0.0, (sum, o) => sum + o.totalPrice);

    // Top meals
    final mealCounts = <String, int>{};
    for (var order in todayOrders) {
      if (order.status == models.OrderStatus.cancelled) continue;
      for (var item in order.items) {
        mealCounts[item.meal.name] =
            (mealCounts[item.meal.name] ?? 0) + item.quantity;
      }
    }
    final topMeals = mealCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalOrders': todayOrders.length,
      'pendingOrders':
          todayOrders.where((o) => o.status == models.OrderStatus.pending).length,
      'preparingOrders':
          todayOrders.where((o) => o.status == models.OrderStatus.preparing).length,
      'completedOrders':
          todayOrders.where((o) => o.status == models.OrderStatus.completed).length,
      'cancelledOrders':
          todayOrders.where((o) => o.status == models.OrderStatus.cancelled).length,
      'revenue': revenue,
      'topMeals': topMeals.take(5).toList(),
    };
  }

  @override
  void dispose() {
    _allOrdersSubscription?.cancel();
    _userOrdersSubscription?.cancel();
    super.dispose();
  }
}
