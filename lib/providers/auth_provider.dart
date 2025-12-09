import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';

/// 认证状态管理
class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  final WebSocketService _wsService = WebSocketService();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null && StorageService.isLoggedIn();
  WebSocketService get wsService => _wsService;

  /// 邮箱登录
  Future<bool> login({
    required String email,
    required String password,
    String? deviceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 调用登录API
      final response = await ApiService.emailLogin(
        email: email,
        password: password,
        deviceId: deviceId,
      );

      if (response.isSuccess && response.token != null) {
        // 保存Token
        await StorageService.saveToken(response.token!);
        if (deviceId != null) {
          await StorageService.saveDeviceId(deviceId);
        }

        // 获取用户信息
        final userInfo = await ApiService.getUserInfo();
        if (userInfo != null) {
          _user = userInfo;
          await StorageService.saveUserId(userInfo.id);
          
          // 连接WebSocket
          _wsService.onMessageReceived = (data) {
            // 处理WebSocket消息
            print('收到WebSocket消息: ${data['cmd']}');
          };
          await _wsService.connect();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = '获取用户信息失败';
        }
      } else {
        _errorMessage = response.msg;
      }
    } catch (e) {
      _errorMessage = '登录失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 手机号验证码登录
  Future<bool> loginWithMobile({
    required String mobile,
    required String captcha,
    required String deviceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 调用手机号登录API
      final response = await ApiService.verificationLogin(
        mobile: mobile,
        captcha: captcha,
        deviceId: deviceId,
      );

      if (response.isSuccess && response.token != null) {
        // 保存Token
        await StorageService.saveToken(response.token!);
        await StorageService.saveDeviceId(deviceId);

        // 获取用户信息
        final userInfo = await ApiService.getUserInfo();
        if (userInfo != null) {
          _user = userInfo;
          await StorageService.saveUserId(userInfo.id);
          
          // 连接WebSocket
          _wsService.onMessageReceived = (data) {
            // 处理WebSocket消息
            print('收到WebSocket消息: ${data['cmd']}');
          };
          await _wsService.connect();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = '获取用户信息失败';
        }
      } else {
        _errorMessage = response.msg;
      }
    } catch (e) {
      _errorMessage = '登录失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 退出登录
  Future<void> logout() async {
    _wsService.disconnect();
    await StorageService.clear();
    _user = null;
    notifyListeners();
  }

  /// 自动登录（检查本地Token）
  Future<bool> autoLogin() async {
    if (!StorageService.isLoggedIn()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 获取用户信息
      final userInfo = await ApiService.getUserInfo();
      if (userInfo != null) {
        _user = userInfo;
        
        // 连接WebSocket
        await _wsService.connect();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('自动登录失败: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

