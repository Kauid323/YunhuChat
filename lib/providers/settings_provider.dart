import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  Color _seedColor = Colors.blue;
  List<String> _conversationAppBarActions = <String>['search'];
  List<String> _contactAppBarActions = <String>['refresh'];

  List<String> _bottomNavItems = <String>[
    'conversation',
    'community',
    'contacts',
    'discover',
    'profile',
  ];

  final List<String> _conversationAvailableActions = const <String>['search'];
  final List<String> _contactAvailableActions = const <String>['refresh'];

  final List<String> _bottomNavAvailableItems = const <String>[
    'conversation',
    'community',
    'contacts',
    'discover',
    'profile',
  ];

  Color get seedColor => _seedColor;

  String get seedColorHex => _seedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase();

  List<String> get conversationAppBarActions => List<String>.from(_conversationAppBarActions);
  List<String> get contactAppBarActions => List<String>.from(_contactAppBarActions);
  List<String> get conversationAvailableActions => List<String>.from(_conversationAvailableActions);
  List<String> get contactAvailableActions => List<String>.from(_contactAvailableActions);

  List<String> get bottomNavItems => List<String>.from(_bottomNavItems);
  List<String> get bottomNavAvailableItems => List<String>.from(_bottomNavAvailableItems);

  SettingsProvider() {
    _load();
  }

  void _load() {
    final raw = StorageService.getThemeSeedColor();
    final parsed = _tryParseArgbHex(raw);
    if (parsed != null) {
      _seedColor = parsed;
    }

    _conversationAppBarActions = StorageService.getConversationAppBarActions();
    _contactAppBarActions = StorageService.getContactAppBarActions();

    _bottomNavItems = StorageService.getBottomNavItems();
  }

  Future<bool> setSeedColorHex(String hex) async {
    final parsed = _tryParseArgbHex(hex);
    if (parsed == null) return false;
    _seedColor = parsed;
    await StorageService.saveThemeSeedColor(_normalizeHex(hex));
    notifyListeners();
    return true;
  }

  Future<void> reorderConversationActions(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _conversationAppBarActions.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target >= _conversationAppBarActions.length) target = _conversationAppBarActions.length - 1;
    final item = _conversationAppBarActions.removeAt(oldIndex);
    _conversationAppBarActions.insert(target, item);
    await StorageService.saveConversationAppBarActions(_conversationAppBarActions);
    notifyListeners();
  }

  Future<void> toggleConversationAction(String action, bool enabled) async {
    if (!_conversationAvailableActions.contains(action)) return;
    if (enabled) {
      if (!_conversationAppBarActions.contains(action)) {
        _conversationAppBarActions.add(action);
      }
    } else {
      _conversationAppBarActions.remove(action);
    }
    await StorageService.saveConversationAppBarActions(_conversationAppBarActions);
    notifyListeners();
  }

  Future<void> reorderContactActions(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _contactAppBarActions.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target >= _contactAppBarActions.length) target = _contactAppBarActions.length - 1;
    final item = _contactAppBarActions.removeAt(oldIndex);
    _contactAppBarActions.insert(target, item);
    await StorageService.saveContactAppBarActions(_contactAppBarActions);
    notifyListeners();
  }

  Future<void> toggleContactAction(String action, bool enabled) async {
    if (!_contactAvailableActions.contains(action)) return;
    if (enabled) {
      if (!_contactAppBarActions.contains(action)) {
        _contactAppBarActions.add(action);
      }
    } else {
      _contactAppBarActions.remove(action);
    }
    await StorageService.saveContactAppBarActions(_contactAppBarActions);
    notifyListeners();
  }

  static String _normalizeHex(String hex) {
    var s = hex.trim();
    if (s.startsWith('0x') || s.startsWith('0X')) {
      s = s.substring(2);
    }
    if (s.startsWith('#')) {
      s = s.substring(1);
    }
    return s.toUpperCase();
  }

  static Color? _tryParseArgbHex(String? hex) {
    if (hex == null) return null;
    var s = _normalizeHex(hex);
    if (s.length == 6) {
      s = 'FF$s';
    }
    if (s.length != 8) return null;
    final value = int.tryParse(s, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  Future<void> reorderBottomNavItems(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _bottomNavItems.length) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target >= _bottomNavItems.length) target = _bottomNavItems.length - 1;
    final item = _bottomNavItems.removeAt(oldIndex);
    _bottomNavItems.insert(target, item);
    await StorageService.saveBottomNavItems(_bottomNavItems);
    notifyListeners();
  }

  Future<void> toggleBottomNavItem(String item, bool enabled) async {
    if (!_bottomNavAvailableItems.contains(item)) return;
    if (enabled) {
      if (!_bottomNavItems.contains(item)) {
        _bottomNavItems.add(item);
      }
    } else {
      if (_bottomNavItems.length <= 2) return;
      _bottomNavItems.remove(item);
    }
    await StorageService.saveBottomNavItems(_bottomNavItems);
    notifyListeners();
  }
}
