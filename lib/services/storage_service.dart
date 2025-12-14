import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/contact_model.dart';

/// 本地存储服务
class StorageService {
  static const String _keyToken = 'user_token';
  static const String _keyUserId = 'user_id';
  static const String _keyDeviceId = 'device_id';

  static const String _keyAddressBookCache = 'address_book_cache';

  static const String _keyThemeSeedColor = 'theme_seed_color';
  static const String _keyWebsocketManualDisabled = 'ws_manual_disabled';

  static const String _keyConversationAppBarActions = 'appbar_actions_conversation';
  static const String _keyContactAppBarActions = 'appbar_actions_contact';

  static const String _keyBottomNavItems = 'bottom_nav_items';
  
  static SharedPreferences? _prefs;

  /// 初始化
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 保存Token
  static Future<bool> saveToken(String token) async {
    return await _prefs?.setString(_keyToken, token) ?? false;
  }

  /// 获取Token
  static String? getToken() {
    return _prefs?.getString(_keyToken);
  }

  /// 保存用户ID
  static Future<bool> saveUserId(String userId) async {
    return await _prefs?.setString(_keyUserId, userId) ?? false;
  }

  /// 获取用户ID
  static String? getUserId() {
    return _prefs?.getString(_keyUserId);
  }

  /// 保存设备ID
  static Future<bool> saveDeviceId(String deviceId) async {
    return await _prefs?.setString(_keyDeviceId, deviceId) ?? false;
  }

  /// 获取设备ID
  static String? getDeviceId() {
    return _prefs?.getString(_keyDeviceId);
  }

  /// 清除所有数据（退出登录）
  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  /// 检查是否已登录
  static bool isLoggedIn() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> saveThemeSeedColor(String argbHex) async {
    return await _prefs?.setString(_keyThemeSeedColor, argbHex) ?? false;
  }

  static String? getThemeSeedColor() {
    return _prefs?.getString(_keyThemeSeedColor);
  }

  static Future<bool> setWebsocketManualDisabled(bool disabled) async {
    return await _prefs?.setBool(_keyWebsocketManualDisabled, disabled) ?? false;
  }

  static bool isWebsocketManualDisabled() {
    return _prefs?.getBool(_keyWebsocketManualDisabled) ?? false;
  }

  static Future<bool> saveConversationAppBarActions(List<String> actions) async {
    return await _prefs?.setStringList(_keyConversationAppBarActions, actions) ?? false;
  }

  static List<String> getConversationAppBarActions() {
    return _prefs?.getStringList(_keyConversationAppBarActions) ?? <String>['search'];
  }

  static Future<bool> saveContactAppBarActions(List<String> actions) async {
    return await _prefs?.setStringList(_keyContactAppBarActions, actions) ?? false;
  }

  static List<String> getContactAppBarActions() {
    return _prefs?.getStringList(_keyContactAppBarActions) ?? <String>['refresh'];
  }

  static Future<bool> saveBottomNavItems(List<String> items) async {
    return await _prefs?.setStringList(_keyBottomNavItems, items) ?? false;
  }

  static List<String> getBottomNavItems() {
    final items = _prefs?.getStringList(_keyBottomNavItems);
    final fallback = <String>['conversation', 'community', 'contacts', 'discover', 'profile'];
    if (items == null || items.length < 2) return fallback;
    return items;
  }

  static bool hasAddressBookCache() {
    final raw = _prefs?.getString(_keyAddressBookCache);
    return raw != null && raw.isNotEmpty;
  }

  static List<AddressBookGroup> getAddressBookCache() {
    final raw = _prefs?.getString(_keyAddressBookCache);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => AddressBookGroup.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> saveAddressBookCache(List<AddressBookGroup> groups) async {
    final raw = jsonEncode(groups.map((e) => e.toJson()).toList());
    return await _prefs?.setString(_keyAddressBookCache, raw) ?? false;
  }
}

