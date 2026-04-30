// Menu model for daily menu information
import 'package:cloud_firestore/cloud_firestore.dart';

class Menu {
  final String id;
  final DateTime date;
  final List<String> mealIds; // References to meal documents
  final String cafeteriaId;

  Menu({
    required this.id,
    required this.date,
    required this.mealIds,
    required this.cafeteriaId,
  });

  // Convert from Firestore document
  factory Menu.fromFirestore(Map<String, dynamic> data, String id) {
    return Menu(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      mealIds: List<String>.from(data['mealIds'] ?? []),
      cafeteriaId: data['cafeteriaId'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'mealIds': mealIds,
      'cafeteriaId': cafeteriaId,
    };
  }
}
