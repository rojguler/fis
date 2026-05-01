import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmailService {
  // .env dosyasından güvenli bir şekilde okunan Brevo API bilgileri
  static String get _brevoApiKey => dotenv.env['BREVO_API_KEY'] ?? '';
  static String get _senderEmail => dotenv.env['SENDER_EMAIL'] ?? '';
  static String get _senderName  => dotenv.env['SENDER_NAME']  ?? 'iKAS';


  /// Firestore'daki kullanıcılara menü güncelleme maili gönderir
  static Future<void> sendMenuUpdateEmail() async {
    try {
      // 1. Kullanıcıların maillerini Firestore'dan çek (bildirimleri açık olanlar)
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      List<Map<String, String>> bccList = [];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        
        // Eğer email alanı varsa listeye ekle (eğer özel bir notification izin alanı varsa buraya if koşulu eklenebilir)
        if (data.containsKey('email') && data['email'] != null && data['email'].toString().isNotEmpty) {
          bccList.add({'email': data['email'].toString()});
        }
      }

      // Eğer kimse yoksa işlem yapma
      if (bccList.isEmpty) {
        print('Gönderilecek e-posta adresi bulunamadı.');
        return;
      }

      // 2. Brevo API'sine gönderilecek JSON formatı
      final payload = {
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [{'email': _senderEmail, 'name': _senderName}], // To'da gizlilik için kendini göster
        'bcc': bccList, // Alıcılar BCC'de olacak (birbirini görmez)
        'subject': '🍽️ Yeni Menü Güncellendi!',
        'htmlContent': '''
          <div style="font-family: sans-serif; text-align: center; color: #333; padding: 20px;">
              <h2>Yeni Menü Yayında 🚀</h2>
              <p>Bugünün yemeklerini kontrol etmeyi unutma!</p>
              <br>
              <p>Uygulamayı aç → <b>iKAS</b></p>
          </div>
        '''
      };

      // 3. Brevo API'ye HTTP POST İsteği At
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'api-key': _brevoApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      // 4. Yanıtı Kontrol Et
      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Mail başarıyla gönderildi! Toplam ${bccList.length} kişiye ulaştı.');
      } else {
        print('Mail gönderilirken bir hata oluştu: ${response.statusCode}');
        print('Hata Detayı: ${response.body}');
      }
    } catch (e) {
      print('Email Servisi Hatası: $e');
    }
  }

  /// Sipariş durumu güncellendiğinde kullanıcıya mail gönderir
  static Future<void> sendOrderStatusEmail({
    required String userEmail,
    required String orderId,
    required String newStatus,
    required String statusText,
  }) async {
    try {
      if (userEmail.isEmpty) return;

      final payload = {
        'sender': {'name': _senderName, 'email': _senderEmail},
        'to': [{'email': userEmail}],
        'subject': '📦 Sipariş Durumunuz Güncellendi: $statusText',
        'htmlContent': '''
          <div style="font-family: sans-serif; text-align: center; color: #333; padding: 20px;">
              <h2>Siparişiniz Hakkında Bir Gelişme Var!</h2>
              <p>Sipariş Numaranız: <b>#${orderId.substring(0, 5)}</b></p>
              <h3 style="color: #FF5722;">Durum: $statusText</h3>
              <p>Afiyet olsun!</p>
              <br>
              <p>Detayları kontrol etmek için <b>iKAS</b>'ı açın.</p>
          </div>
        '''
      };

      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'api-key': _brevoApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Sipariş maili $userEmail adresine başarıyla gönderildi!');
      } else {
        print('Sipariş maili hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Sipariş Email Servisi Hatası: $e');
    }
  }
}

