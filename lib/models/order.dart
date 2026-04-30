// Order model for storing order information
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum OrderStatus {
  pending,    // Sipariş alındı, hazırlanmayı bekliyor
  preparing,  // Hazırlanıyor
  ready,      // Hazır, teslim alınabilir
  completed,  // Tamamlandı (teslim alındı & ödendi)
  cancelled,  // İptal edildi
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final DateTime createdAt;
  final OrderStatus status;
  final String? notes;
  final int orderNumber;        // Kısa okunabilir sipariş no (#1042)
  final int? estimatedMinutes; // Admin tarafından atanan tahmini süre

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.notes,
    this.orderNumber = 0,
    this.estimatedMinutes,
  });

  // Convert from Firestore document
  factory Order.fromFirestore(Map<String, dynamic> data, String id, List<CartItem> items) {
    return Order(
      id: id,
      userId: data['userId'] ?? '',
      items: items,
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere(
        (s) => s.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      notes: data['notes'],
      orderNumber: (data['orderNumber'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (data['estimatedMinutes'] as num?)?.toInt(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
      'notes': notes,
      'orderNumber': orderNumber,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  /// Okunabilir sipariş numarası: #1042
  String get displayNumber => orderNumber > 0 ? '#${orderNumber.toString().padLeft(4, '0')}' : '#----';

  // Status display text (EN)
  String get statusText {
    switch (status) {
      case OrderStatus.pending:    return 'Waiting';
      case OrderStatus.preparing:  return 'Preparing';
      case OrderStatus.ready:      return 'Ready for Pickup! 🎉';
      case OrderStatus.completed:  return 'Completed';
      case OrderStatus.cancelled:  return 'Cancelled';
    }
  }

  // Status display text (TR)
  String get statusTextTr {
    switch (status) {
      case OrderStatus.pending:    return 'Bekleniyor';
      case OrderStatus.preparing:  return 'Hazırlanıyor';
      case OrderStatus.ready:      return 'Teslim Almaya Hazır! 🎉';
      case OrderStatus.completed:  return 'Tamamlandı';
      case OrderStatus.cancelled:  return 'İptal Edildi';
    }
  }

  String statusTextLocalized(bool isTurkish) =>
      isTurkish ? statusTextTr : statusText;

  // Status color
  int get statusColorValue {
    switch (status) {
      case OrderStatus.pending:    return 0xFFFF9800; // orange
      case OrderStatus.preparing:  return 0xFF2196F3; // blue
      case OrderStatus.ready:      return 0xFF4CAF50; // green
      case OrderStatus.completed:  return 0xFF9E9E9E; // grey
      case OrderStatus.cancelled:  return 0xFFF44336; // red
    }
  }

  // Check if order can be cancelled (only while pending)
  bool get canCancel => status == OrderStatus.pending;
}
