import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart' as models;

class EmailService {
  static String get _brevoApiKey => dotenv.env['BREVO_API_KEY'] ?? '';
  static String get _senderEmail => dotenv.env['SENDER_EMAIL'] ?? '';
  static String get _senderName  => dotenv.env['SENDER_NAME']  ?? 'iKAS Fis';

  // Deep link scheme — matches AndroidManifest intent-filter
  static const String _deepLinkScheme = 'ikasfis';

  /// Firestore'daki tüm kullanıcılara günlük menü maili gönderir
  static Future<void> sendMenuUpdateEmail({bool isTurkish = true}) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final List<Map<String, String>> bccList = [];

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final email = data['email']?.toString() ?? '';
        if (email.isNotEmpty) bccList.add({'email': email});
      }

      if (bccList.isEmpty) return;

      final subject  = isTurkish ? '🍽️ Yeni Menü Yayında! Açsana!' : '🍽️ Today\'s Menu is Live!';
      final preheader = isTurkish ? 'Bugünün lezzetleri sizi bekliyor 🚀' : 'Fresh flavors are waiting for you 🚀';
      final headline = isTurkish ? 'Bugünün Menüsü Hazır 🚀' : 'Today\'s Menu is Ready 🚀';
      final bodyHtml = isTurkish
          ? 'Şeflerimiz bugünün menüsünü özenle hazırladı. <br>Hemen iKAS Fis uygulamasını açarak bugünkü lezzetlere göz atabilir, sipariş verebilirsiniz!'
          : 'Our chefs have carefully prepared today\'s menu. <br>Open iKAS Fis app now to check the day\'s specials and place your order!';
      final btnText  = isTurkish ? '🍴 Menüyü Gör' : '🍴 View Today\'s Menu';
      final deepLink = '$_deepLinkScheme://home';

      final payload = {
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to':  [{'email': _senderEmail, 'name': _senderName}],
        'bcc': bccList,
        'subject': subject,
        'htmlContent': _buildMenuEmailHtml(
          headline: headline,
          bodyHtml: bodyHtml,
          btnText: btnText,
          btnUrl: deepLink,
          preheader: preheader,
          isTurkish: isTurkish,
        ),
      };

      await _postEmail(payload);
    } catch (e) {
      print('Email Servisi Hatası: $e');
    }
  }

  /// Sipariş durumu değişince kullanıcıya mail gönderir
  static Future<void> sendOrderStatusEmail({
    required String userEmail,
    required String orderId,
    required String statusText,
    bool isTurkish = true,
  }) async {
    try {
      if (userEmail.isEmpty) return;

      final shortId = orderId.length >= 8
          ? orderId.substring(orderId.length - 8).toUpperCase()
          : orderId.toUpperCase();

      final subject   = isTurkish ? '📦 Siparişiniz Güncellendi: $statusText' : '📦 Order Updated: $statusText';
      final preheader = isTurkish ? 'Siparişinizde yeni bir gelişme var!' : 'There\'s a new update on your order!';
      final headline  = isTurkish ? 'Sipariş Güncellemesi' : 'Order Update';
      final deepLink  = '$_deepLinkScheme://tracking/$orderId';
      final btnText   = isTurkish ? '📍 Siparişi Takip Et' : '📍 Track My Order';

      final rows = [
        _tableRow(isTurkish ? 'Sipariş No' : 'Order No',   '#$shortId'),
        _tableRow(isTurkish ? 'Yeni Durum' : 'New Status', statusText),
      ].join();

      await _postEmail({
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [{'email': userEmail}],
        'subject': subject,
        'htmlContent': _buildOrderEmailHtml(
          headline: headline,
          rows: rows,
          btnText: btnText,
          btnUrl: deepLink,
          preheader: preheader,
          isTurkish: isTurkish,
        ),
      });
    } catch (e) {
      print('Sipariş Email Servisi Hatası: $e');
    }
  }

  /// Sipariş oluşturulunca onay maili gönderir
  static Future<void> sendOrderConfirmationEmail(models.Order order, {bool isTurkish = true}) async {
    try {
      final userDoc   = await FirebaseFirestore.instance.collection('users').doc(order.userId).get();
      final userEmail = userDoc.data()?['email'] ?? '';
      final userName  = userDoc.data()?['name'] ?? (isTurkish ? 'Değerli Müşterimiz' : 'Dear Customer');
      if (userEmail.isEmpty) return;

      final shortId  = order.id.length >= 8
          ? order.id.substring(order.id.length - 8).toUpperCase()
          : order.id.toUpperCase();

      final subject   = isTurkish ? '✅ Siparişiniz Alındı — #$shortId' : '✅ Order Confirmed — #$shortId';
      final preheader = isTurkish ? 'Siparişiniz mutfağa iletildi, hazırlanmaya başlandı!' : 'Your order reached the kitchen and is being prepared!';
      final headline  = isTurkish ? 'Siparişiniz İçin Teşekkürler, $userName!' : 'Thank You for Your Order, $userName!';
      final deepLink  = '$_deepLinkScheme://order/${order.id}';
      final btnText   = isTurkish ? '📦 Siparişimi Görüntüle' : '📦 View My Order';

      // Build item rows
      final itemLines = order.items.map((item) {
        return _tableRow(
          '${item.quantity}× ${item.meal.name}',
          '₺${item.totalPrice.toStringAsFixed(2)}',
        );
      }).join();

      final rows = [
        _tableRow(isTurkish ? 'Sipariş No' : 'Order No', '#$shortId'),
        itemLines,
        _tableRowBold(
          isTurkish ? 'Toplam Tutar' : 'Total Amount',
          '₺${order.totalPrice.toStringAsFixed(2)}',
        ),
        _tableRow(
          isTurkish ? 'Ödeme' : 'Payment',
          isTurkish ? 'Markette Ödeme' : 'Pay at Counter',
        ),
      ];

      await _postEmail({
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [{'email': userEmail}],
        'subject': subject,
        'htmlContent': _buildOrderEmailHtml(
          headline: headline,
          rows: rows.join(),
          btnText: btnText,
          btnUrl: deepLink,
          preheader: preheader,
          isTurkish: isTurkish,
          isConfirmation: true,
        ),
      });
    } catch (e) {
      print('Onay Maili Hatası: $e');
    }
  }

  /// Admin e-postasına stok uyarısı gönderir (roj.gulerr@gmail.com sabit)
  static Future<void> sendAdminStockAlertEmail({
    required String adminEmail,
    required String supplierEmail,
    required String mealName,
    required int currentStock,
    required int requestedQuantity,
    bool isTurkish = true,
  }) async {
    try {
      if (adminEmail.isEmpty) return;

      final subject = isTurkish
          ? '📋 Stok Talebi Gönderildi: $mealName'
          : '📋 Restock Request Sent: $mealName';
      final preheader = isTurkish
          ? 'Tedarikçiye stok yenileme talebi iletildi'
          : 'Restock request forwarded to supplier';
      final headline = isTurkish
          ? '📋 Stok Talebi Bilgilendirmesi'
          : '📋 Restock Request Notification';

      final introHtml = isTurkish
          ? 'Aşağıdaki ürün için tedarikçiye (<b>$supplierEmail</b>) stok yenileme talebi iletildi.'
          : 'A restock request was sent to supplier (<b>$supplierEmail</b>) for the item below.';

      final rows = [
        _tableRow(isTurkish ? 'Ürün Adı' : 'Product Name', mealName),
        _tableRowWarning(
          isTurkish ? 'Mevcut Stok' : 'Current Stock',
          '$currentStock ${isTurkish ? "adet" : "units"}',
        ),
        _tableRowBold(
          isTurkish ? 'Talep Edilen Miktar' : 'Requested Quantity',
          '$requestedQuantity ${isTurkish ? "adet" : "units"}',
        ),
        _tableRow(isTurkish ? 'Tedarikçi E-posta' : 'Supplier Email', supplierEmail),
      ];

      final signoff = isTurkish
          ? 'Saygılarımızla,<br><b>iKAS Fis Otomatik Bildirim Sistemi</b>'
          : 'Best regards,<br><b>iKAS Fis Automated Notification System</b>';

      await _postEmail({
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [{'email': adminEmail, 'name': 'iKAS Admin'}],
        'subject': subject,
        'htmlContent': _buildSupplierEmailHtml(
          headline: headline,
          introHtml: introHtml,
          rows: rows.join(),
          signoff: signoff,
          btnText: isTurkish ? '📊 Admin Paneli' : '📊 Admin Panel',
          btnUrl: 'ikasfis://admin',
          preheader: preheader,
          isTurkish: isTurkish,
        ),
      });
    } catch (e) {
      print('Admin Stok Bildirim Hatası: $e');
    }
  }

  /// Tedarikçiye stok uyarısı + yenileme talebi gönderir
  static Future<void> sendSupplierRestockEmail({
    required String supplierEmail,
    required String mealName,
    required int currentStock,
    required int requestedQuantity,
    bool isTurkish = true,
  }) async {
    try {
      if (supplierEmail.isEmpty) return;

      final subject   = isTurkish ? '⚠️ Acil Stok Talebi: $mealName' : '⚠️ Urgent Restock Request: $mealName';
      final preheader = isTurkish ? 'iKAS Fis — $mealName stoğu kritik seviyede!' : 'iKAS Fis — $mealName stock is critically low!';
      final headline  = isTurkish ? '⚠️ Stok Yenileme Talebi' : '⚠️ Restock Request';

      // Supplier gets a mailto reply link (not app deep-link)
      final btnUrl  = 'mailto:$_senderEmail?subject=${Uri.encodeComponent(isTurkish ? "Stok Talebi Onayı: $mealName" : "Restock Confirmation: $mealName")}';
      final btnText = isTurkish ? '✉️ Talebi Onayla' : '✉️ Confirm Request';

      final introHtml = isTurkish
          ? 'Sayın Tedarikçimiz,<br><br>Aşağıdaki ürünün stok seviyesi <b>kritik düzeye</b> düşmüştür. Lütfen en kısa sürede teslimat organize ediniz.'
          : 'Dear Supplier,<br><br>The stock level of the item below has dropped to a <b>critical level</b>. Please arrange delivery at your earliest convenience.';

      final rows = [
        _tableRow(isTurkish ? 'Ürün Adı' : 'Product Name', mealName),
        _tableRowWarning(
          isTurkish ? 'Mevcut Stok' : 'Current Stock',
          '$currentStock ${isTurkish ? "adet" : "units"}',
        ),
        _tableRowBold(
          isTurkish ? 'Talep Edilen Miktar' : 'Requested Quantity',
          '$requestedQuantity ${isTurkish ? "adet" : "units"}',
        ),
      ];

      final signoff = isTurkish
          ? 'Saygılarımızla,<br><b>iKAS Fis Mutfak Yönetimi</b>'
          : 'Best regards,<br><b>iKAS Fis Kitchen Management</b>';

      await _postEmail({
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [{'email': supplierEmail}],
        'subject': subject,
        'htmlContent': _buildSupplierEmailHtml(
          headline: headline,
          introHtml: introHtml,
          rows: rows.join(),
          signoff: signoff,
          btnText: btnText,
          btnUrl: btnUrl,
          preheader: preheader,
          isTurkish: isTurkish,
        ),
      });
    } catch (e) {
      print('Tedarikçi Mail Servisi Hatası: $e');
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  static Future<void> _postEmail(Map<String, dynamic> payload) async {
    if (_brevoApiKey.isEmpty) {
      print('⚠️  BREVO_API_KEY is not set in .env — email not sent');
      return;
    }
    final response = await http.post(
      Uri.parse('https://api.brevo.com/v3/smtp/email'),
      headers: {
        'api-key': _brevoApiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(payload),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      print('Mail gönderim hatası: ${response.statusCode} — ${response.body}');
    }
  }

  // Table row helpers
  static String _tableRow(String label, String value) => '''
    <tr>
      <td style="padding:10px 16px;border-bottom:1px solid #F3F4F6;color:#6B7280;font-size:14px;width:45%;">$label</td>
      <td style="padding:10px 16px;border-bottom:1px solid #F3F4F6;color:#111827;font-size:14px;font-weight:600;">$value</td>
    </tr>''';

  static String _tableRowBold(String label, String value) => '''
    <tr style="background:#F0FDF4;">
      <td style="padding:12px 16px;color:#065F46;font-size:14px;font-weight:700;width:45%;">$label</td>
      <td style="padding:12px 16px;color:#065F46;font-size:16px;font-weight:800;">$value</td>
    </tr>''';

  static String _tableRowWarning(String label, String value) => '''
    <tr style="background:#FEF9C3;">
      <td style="padding:10px 16px;color:#92400E;font-size:14px;width:45%;">$label</td>
      <td style="padding:10px 16px;color:#B45309;font-size:14px;font-weight:700;">$value</td>
    </tr>''';

  // ─── HTML Templates ────────────────────────────────────────────────────────

  static String _buildMenuEmailHtml({
    required String headline,
    required String bodyHtml,
    required String btnText,
    required String btnUrl,
    required String preheader,
    required bool isTurkish,
  }) {
    final footer = isTurkish
        ? 'Bu e-postayı iKAS Fis uygulamasına kayıtlı olduğunuz için alıyorsunuz.'
        : 'You are receiving this email because you are registered with iKAS Fis.';
    return '''<!DOCTYPE html>
<html lang="${isTurkish ? 'tr' : 'en'}">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>${isTurkish ? 'Yeni Menü' : 'New Menu'}</title></head>
<body style="margin:0;padding:0;background:#F9FAFB;font-family:'Segoe UI',Tahoma,Verdana,sans-serif;">
<!-- preheader -->
<span style="display:none;max-height:0;overflow:hidden;">$preheader</span>
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F9FAFB;padding:40px 0;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:white;border-radius:20px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);max-width:600px;">
  <!-- HEADER -->
  <tr><td style="background:linear-gradient(135deg,#166534 0%,#22C55E 100%);padding:36px 40px;text-align:center;">
    <h1 style="margin:0;color:white;font-size:28px;font-weight:800;letter-spacing:-0.5px;">🍽️ iKAS Fis</h1>
    <p style="margin:8px 0 0;color:rgba(255,255,255,0.85);font-size:14px;">${isTurkish ? 'Yemekhane Sipariş Sistemi' : 'Cafeteria Order System'}</p>
  </td></tr>
  <!-- HERO -->
  <tr><td style="padding:48px 40px 32px;text-align:center;">
    <div style="font-size:56px;margin-bottom:20px;">🚀</div>
    <h2 style="margin:0 0 16px;color:#111827;font-size:26px;font-weight:800;">$headline</h2>
    <p style="margin:0;color:#6B7280;font-size:16px;line-height:1.7;">$bodyHtml</p>
  </td></tr>
  <!-- CTA BUTTON -->
  <tr><td style="padding:0 40px 48px;text-align:center;">
    <a href="$btnUrl"
       style="display:inline-block;background:linear-gradient(135deg,#166534,#22C55E);color:white;text-decoration:none;
              padding:16px 40px;border-radius:14px;font-size:17px;font-weight:700;
              box-shadow:0 6px 20px rgba(34,197,94,0.35);letter-spacing:0.3px;">
      $btnText
    </a>
    <p style="margin:14px 0 0;color:#9CA3AF;font-size:12px;">
      ${isTurkish ? 'Butona tıklayarak doğrudan uygulamaya yönlendirileceksiniz.' : 'Tapping the button will open the app directly.'}
    </p>
  </td></tr>
  <!-- FOOTER -->
  <tr><td style="background:#F9FAFB;padding:24px 40px;border-top:1px solid #F3F4F6;text-align:center;">
    <p style="margin:0;color:#9CA3AF;font-size:12px;line-height:1.6;">$footer</p>
    <p style="margin:8px 0 0;color:#D1D5DB;font-size:11px;">© 2025 iKAS Fis. ${isTurkish ? 'Tüm hakları saklıdır.' : 'All rights reserved.'}</p>
  </td></tr>
</table>
</td></tr>
</table>
</body></html>''';
  }

  static String _buildOrderEmailHtml({
    required String headline,
    required String rows,
    required String btnText,
    required String btnUrl,
    required String preheader,
    required bool isTurkish,
    bool isConfirmation = false,
  }) {
    final accentColor = isConfirmation ? '#166534' : '#1D4ED8';
    final accentLight = isConfirmation ? '#22C55E' : '#3B82F6';
    final icon        = isConfirmation ? '✅' : '📦';
    final tableTitle  = isTurkish ? (isConfirmation ? 'Sipariş Detayları' : 'Güncelleme Detayları') : (isConfirmation ? 'Order Details' : 'Update Details');
    final footer      = isTurkish
        ? 'Bu e-postayı sipariş verdiğiniz için alıyorsunuz.'
        : 'You are receiving this email because you placed an order.';
    return '''<!DOCTYPE html>
<html lang="${isTurkish ? 'tr' : 'en'}">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#F9FAFB;font-family:'Segoe UI',Tahoma,Verdana,sans-serif;">
<span style="display:none;max-height:0;overflow:hidden;">$preheader</span>
<table width="100%" cellpadding="0" cellspacing="0" style="background:#F9FAFB;padding:40px 0;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:white;border-radius:20px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);max-width:600px;">
  <tr><td style="background:linear-gradient(135deg,$accentColor 0%,$accentLight 100%);padding:36px 40px;text-align:center;">
    <h1 style="margin:0;color:white;font-size:28px;font-weight:800;">$icon iKAS Fis</h1>
    <p style="margin:8px 0 0;color:rgba(255,255,255,0.85);font-size:14px;">${isTurkish ? 'Yemekhane Sipariş Sistemi' : 'Cafeteria Order System'}</p>
  </td></tr>
  <tr><td style="padding:40px 40px 24px;text-align:center;">
    <h2 style="margin:0;color:#111827;font-size:22px;font-weight:800;">$headline</h2>
  </td></tr>
  <!-- Details table -->
  <tr><td style="padding:0 40px 32px;">
    <p style="margin:0 0 12px;color:#374151;font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:0.8px;">$tableTitle</p>
    <table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #E5E7EB;border-radius:12px;overflow:hidden;">
      $rows
    </table>
  </td></tr>
  <!-- CTA -->
  <tr><td style="padding:0 40px 48px;text-align:center;">
    <a href="$btnUrl"
       style="display:inline-block;background:linear-gradient(135deg,$accentColor,$accentLight);color:white;text-decoration:none;
              padding:16px 40px;border-radius:14px;font-size:17px;font-weight:700;
              box-shadow:0 6px 20px rgba(0,0,0,0.15);">
      $btnText
    </a>
    <p style="margin:14px 0 0;color:#9CA3AF;font-size:12px;">
      ${isTurkish ? 'Uygulamada sipariş takip ekranına yönlendirileceksiniz.' : 'You will be directed to the order tracking screen in the app.'}
    </p>
  </td></tr>
  <tr><td style="background:#F9FAFB;padding:24px 40px;border-top:1px solid #F3F4F6;text-align:center;">
    <p style="margin:0;color:#9CA3AF;font-size:12px;">$footer</p>
    <p style="margin:8px 0 0;color:#D1D5DB;font-size:11px;">© 2025 iKAS Fis. ${isTurkish ? 'Tüm hakları saklıdır.' : 'All rights reserved.'}</p>
  </td></tr>
</table>
</td></tr>
</table>
</body></html>''';
  }

  static String _buildSupplierEmailHtml({
    required String headline,
    required String introHtml,
    required String rows,
    required String signoff,
    required String btnText,
    required String btnUrl,
    required String preheader,
    required bool isTurkish,
  }) {
    return '''<!DOCTYPE html>
<html lang="${isTurkish ? 'tr' : 'en'}">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#FFF7ED;font-family:'Segoe UI',Tahoma,Verdana,sans-serif;">
<span style="display:none;max-height:0;overflow:hidden;">$preheader</span>
<table width="100%" cellpadding="0" cellspacing="0" style="background:#FFF7ED;padding:40px 0;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:white;border-radius:20px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);max-width:600px;">
  <tr><td style="background:linear-gradient(135deg,#92400E 0%,#F59E0B 100%);padding:36px 40px;text-align:center;">
    <h1 style="margin:0;color:white;font-size:26px;font-weight:800;">⚠️ iKAS Fis — ${isTurkish ? 'Stok Yönetimi' : 'Stock Management'}</h1>
  </td></tr>
  <tr><td style="padding:40px 40px 24px;">
    <h2 style="margin:0 0 16px;color:#111827;font-size:20px;font-weight:800;">$headline</h2>
    <p style="margin:0;color:#374151;font-size:15px;line-height:1.7;">$introHtml</p>
  </td></tr>
  <tr><td style="padding:0 40px 32px;">
    <table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #FDE68A;border-radius:12px;overflow:hidden;background:#FFFBEB;">
      $rows
    </table>
  </td></tr>
  <tr><td style="padding:0 40px 16px;">
    <p style="margin:0;color:#374151;font-size:15px;line-height:1.7;">$signoff</p>
  </td></tr>
  <tr><td style="padding:0 40px 48px;text-align:center;">
    <a href="$btnUrl"
       style="display:inline-block;background:linear-gradient(135deg,#92400E,#F59E0B);color:white;text-decoration:none;
              padding:16px 40px;border-radius:14px;font-size:17px;font-weight:700;
              box-shadow:0 6px 20px rgba(245,158,11,0.35);">
      $btnText
    </a>
  </td></tr>
  <tr><td style="background:#FFF7ED;padding:24px 40px;border-top:1px solid #FDE68A;text-align:center;">
    <p style="margin:0;color:#9CA3AF;font-size:12px;">© 2025 iKAS Fis. ${isTurkish ? 'Tüm hakları saklıdır.' : 'All rights reserved.'}</p>
  </td></tr>
</table>
</td></tr>
</table>
</body></html>''';
  }
}
