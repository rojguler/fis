import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/coupon_service.dart';
import '../services/language_service.dart';
import '../main.dart';

class CouponScreen extends StatelessWidget {
  const CouponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Provider.of<LanguageService>(context);
    return Scaffold(
      backgroundColor: isDark ? IKASColors.darkBg : IKASColors.background,
      appBar: AppBar(
        title: Text(lang.isTurkish ? 'Kuponlarım' : 'My Coupons', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<CouponService>(
        builder: (context, couponService, _) {
          final activeCoupons = couponService.activeCoupons;
          final allCoupons = couponService.coupons;
          final inactiveCoupons = allCoupons.where((c) => !c.isValid).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (activeCoupons.isEmpty && inactiveCoupons.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      lang.isTurkish ? 'Henüz kupon bulunmuyor.' : 'No coupons available.',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ),
                ),
              if (activeCoupons.isNotEmpty) ...[
                Text(
                  lang.isTurkish ? 'Aktif Kuponlar' : 'Active Coupons',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : IKASColors.textDark),
                ),
                const SizedBox(height: 12),
                ...activeCoupons.map((c) {
                  final discount = c.discountPercentage > 0 
                      ? '%${(c.discountPercentage * 100).toInt()} ${lang.isTurkish ? "İNDİRİM" : "OFF"}'
                      : '₺${c.discountAmount.toStringAsFixed(2)} ${lang.isTurkish ? "İNDİRİM" : "OFF"}';
                  final expiry = '${lang.isTurkish ? "Son Kullanım" : "Expires"}: ${c.expiryDate.day}/${c.expiryDate.month}/${c.expiryDate.year}';
                  return _couponCard(isDark, lang, c.code, discount, c.description, expiry, Colors.green);
                }).toList(),
              ],
              
              // Inactive coupons are no longer visible to users
            ],
          );
        }
      ),
    );
  }

  Widget _couponCard(bool isDark, LanguageService lang, String code, String discount, String desc, String expiry, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? IKASColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Left color bar
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 8, color: color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(discount, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                        const SizedBox(height: 4),
                        Text(desc, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87)),
                        const SizedBox(height: 8),
                        Text(expiry, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Clipboard.setData(ClipboardData(text: code));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(code, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
                          const SizedBox(height: 2),
                          Text(lang.isTurkish ? 'KOPYALA' : 'COPY', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Decorative circles for "ticket" look
            Positioned(
              left: -10, top: 0, bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  const circleSize = 20.0;
                  int count = (availableHeight / 25).floor();
                  if (count < 1) count = 1;
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      count,
                      (i) => Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          color: isDark ? IKASColors.darkBg : IKASColors.background,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
