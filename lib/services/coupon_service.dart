import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code;
  final double discountAmount; // flat amount
  final double discountPercentage; // 0.0 to 1.0
  final String description;
  final DateTime expiryDate;
  final bool isActive;
  final int usageCount;
  final double totalProfit;


  Coupon({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.discountPercentage,
    required this.description,
    required this.expiryDate,
    required this.isActive,
    this.usageCount = 0,
    this.totalProfit = 0.0,
  });


  factory Coupon.fromFirestore(Map<String, dynamic> data, String id) {
    return Coupon(
      id: id,
      code: data['code'] ?? '',
      discountAmount: (data['discountAmount'] ?? 0.0).toDouble(),
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
      isActive: data['isActive'] ?? true,
      usageCount: data['usageCount'] ?? 0,
      totalProfit: (data['totalProfit'] ?? 0.0).toDouble(),
    );

  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code.toUpperCase(),
      'discountAmount': discountAmount,
      'discountPercentage': discountPercentage,
      'description': description,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'isActive': isActive,
      'usageCount': usageCount,
      'totalProfit': totalProfit,
    };

  }

  bool get isValid => isActive && expiryDate.isAfter(DateTime.now());
}

class CouponService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Coupon> _coupons = [];
  bool _isLoading = false;

  List<Coupon> get coupons => _coupons;
  List<Coupon> get activeCoupons => _coupons.where((c) => c.isValid).toList();
  bool get isLoading => _isLoading;

  CouponService() {
    _listenToCoupons();
  }

  void _listenToCoupons() {
    _firestore.collection('coupons').snapshots().listen((snapshot) {
      _coupons = snapshot.docs
          .map((doc) => Coupon.fromFirestore(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  // Admin creates a coupon
  Future<void> createCoupon(Coupon coupon) async {
    try {
      await _firestore.collection('coupons').add(coupon.toFirestore());
    } catch (e) {
      debugPrint('Error creating coupon: $e');
      rethrow;
    }
  }

  // Admin updates a coupon
  Future<void> updateCoupon(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('coupons').doc(id).update(data);
    } catch (e) {
      debugPrint('Error updating coupon: $e');
      rethrow;
    }
  }

  // Increment usage count and profit
  Future<void> incrementUsage(String id, double profit) async {
    try {
      await _firestore.collection('coupons').doc(id).update({
        'usageCount': FieldValue.increment(1),
        'totalProfit': FieldValue.increment(profit),
      });
    } catch (e) {
      debugPrint('Error incrementing usage: $e');
    }
  }

  // Admin toggles coupon status
  Future<void> toggleCoupon(String id, bool isActive) async {
    try {
      await _firestore.collection('coupons').doc(id).update({'isActive': isActive});
    } catch (e) {
      debugPrint('Error updating coupon: $e');
    }
  }

  // Admin deletes coupon
  Future<void> deleteCoupon(String id) async {
    try {
      await _firestore.collection('coupons').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting coupon: $e');
    }
  }

  // User applies coupon
  Future<Coupon?> validateCoupon(String code) async {
    try {
      final snapshot = await _firestore.collection('coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        final coupon = Coupon.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
        if (coupon.isValid) {
          return coupon;
        }
      }
      return null; // Not found or invalid
    } catch (e) {
      debugPrint('Error validating coupon: $e');
      return null;
    }
  }

  // Delete all coupons from Firestore
  Future<void> deleteAllCoupons() async {
    try {
      final snapshot = await _firestore.collection('coupons').get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      // No need to fetch, the listener will handle it.
    } catch (e) {
      debugPrint('Error deleting coupons: $e');
      rethrow;
    }
  }

  // Seed 2 clean working coupons
  Future<void> seedInitialCoupons() async {
    final initialCoupons = [
      Coupon(
        id: '',
        code: 'FIS10',
        discountAmount: 0,
        discountPercentage: 0.10, // %10 indirim
        description: '%10 İndirim - Tüm Ürünler',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        isActive: true,
      ),
      Coupon(
        id: '',
        code: 'WELCOME25',
        discountAmount: 25.0, // 25 TL indirim
        discountPercentage: 0,
        description: '25 TL İndirim - Hoşgeldin Kuponu',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        isActive: true,
      ),
    ];

    for (var c in initialCoupons) {
      await createCoupon(c);
    }
  }
}
