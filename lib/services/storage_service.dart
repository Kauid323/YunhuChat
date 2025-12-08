import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务
class StorageService {
  static const String _keyToken = 'user_token';
  static const String _keyUserId = 'user_id';
  static const String _keyDeviceId = 'device_id';
  
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
}

