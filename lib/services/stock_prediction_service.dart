import '../models/order.dart';
import '../models/meal.dart';

class StockPredictionService {
  /// Calculates predicted time remaining for each meal based on consumption rate
  /// in the last [windowHours] hours.
  static Map<String, Duration> predictTimeRemaining(
    List<Order> allOrders,
    List<Meal> meals, {
    int windowHours = 3,
  }) {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(hours: windowHours));
    
    // 1. Filter orders within the time window
    final recentOrders = allOrders.where((o) => 
      o.createdAt.isAfter(windowStart) && o.status != OrderStatus.cancelled
    ).toList();
    
    final predictions = <String, Duration>{};
    
    for (var meal in meals) {
      if (meal.stock <= 0) {
        predictions[meal.id] = Duration.zero;
        continue;
      }
      
      // 2. Calculate total units of THIS meal sold in the window
      int unitsSold = 0;
      for (var order in recentOrders) {
        for (var item in order.items) {
          if (item.meal.id == meal.id) {
            unitsSold += item.quantity;
          }
        }
      }
      
      if (unitsSold > 0) {
        // units per minute = unitsSold / (windowHours * 60)
        double minutesInWindow = windowHours * 60.0;
        double unitsPerMinute = unitsSold / minutesInWindow;
        
        // minutes remaining = current stock / units per minute
        double minutesLeft = meal.stock / unitsPerMinute;
        
        // Cap it at a reasonable amount (e.g. 24 hours) to avoid infinity
        if (minutesLeft > 1440) minutesLeft = 1440;
        
        predictions[meal.id] = Duration(minutes: minutesLeft.round());
      } else {
        // No sales in the window, can't predict based on rate.
        // We could return a very large duration or null.
      }
    }
    
    return predictions;
  }

  /// Returns a human-readable string for the predicted time remaining
  static String getPredictionText(Duration? duration, bool isTurkish) {
    if (duration == null) return isTurkish ? 'Yeterli veri yok' : 'Not enough data';
    if (duration.inMinutes <= 0) return isTurkish ? 'Tükendi' : 'Sold out';
    
    if (duration.inHours >= 24) {
      return isTurkish ? '24+ saat yetecek' : 'Sufficient for 24h+';
    }
    
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final mins = duration.inMinutes % 60;
      if (isTurkish) {
        return 'Tahmini $hours sa $mins dk kaldı';
      } else {
        return 'Est. $hours h $mins m left';
      }
    } else {
      if (isTurkish) {
        return 'Tahmini ${duration.inMinutes} dk içinde tükenebilir';
      } else {
        return 'Est. sold out in ${duration.inMinutes}m';
      }
    }
  }
}
