import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and provides recent search queries across the app.
class SearchHistoryService extends ChangeNotifier {
  static const _key = 'recent_search_queries';
  static const _maxHistory = 10;

  List<String> _history = [];

  List<String> get history => _history;

  SearchHistoryService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _history = prefs.getStringList(_key) ?? [];
    notifyListeners();
  }

  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    
    // Remove if already exists so we can bump it to the top
    _history.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    
    // Insert at front
    _history.insert(0, trimmed);
    
    // Truncate to max size
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }
    
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _history);
  }

  Future<void> removeQuery(String query) async {
    _history.removeWhere((q) => q.toLowerCase() == query.toLowerCase());
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _history);
  }

  Future<void> clearAll() async {
    _history.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
