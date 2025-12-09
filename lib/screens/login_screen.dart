import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'main_navigation.dart';

/// 登录界面
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  final _emailFormKey = GlobalKey<FormState>();
  final _mobileFormKey = GlobalKey<FormState>();
  
  // 邮箱登录
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  // 手机号登录
  final _mobileController = TextEditingController();
  final _captchaCodeController = TextEditingController();
  final _smsCodeController = TextEditingController();
  String? _captchaImageBase64;
  String? _captchaId;
  int _countdown = 0;
  bool _isLoadingCaptcha = false;
  bool _isSendingSms = false;

  @override
  void initState() {
    super.initState();
    // 延迟加载验证码，确保 TabController 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCaptcha();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _captchaCodeController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  /// 加载图片验证码
  Future<void> _loadCaptcha() async {
    setState(() {
      _isLoadingCaptcha = true;
    });

    try {
      final deviceId = StorageService.getDeviceId() ?? 
          DateTime.now().millisecondsSinceEpoch.toString();
      await StorageService.saveDeviceId(deviceId);
      
      final result = await ApiService.getCaptcha(deviceId: deviceId);
      
      if (mounted && result != null) {
        setState(() {
          _captchaImageBase64 = result['b64s']?.toString();
          _captchaId = result['id']?.toString();
          _isLoadingCaptcha = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingCaptcha = false;
          });
          _showError('获取验证码失败');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCaptcha = false;
        });
        _showError('获取验证码失败: ${e.toString()}');
      }
    }
  }

  /// 发送短信验证码
  Future<void> _sendSmsCode() async {
    if (_mobileController.text.trim().isEmpty) {
      _showError('请输入手机号');
      return;
    }
    
    if (_captchaCodeController.text.trim().isEmpty) {
      _showError('请输入图片验证码');
      return;
    }

    if (_captchaId == null) {
      _showError('请先获取验证码');
      return;
    }

    setState(() {
      _isSendingSms = true;
    });

    try {
      final success = await ApiService.getVerificationCode(
        mobile: _mobileController.text.trim(),
        code: _captchaCodeController.text.trim(),
        id: _captchaId!,
      );

      if (mounted) {
        setState(() {
          _isSendingSms = false;
        });

        if (success) {
          _showSuccess('验证码已发送');
          // 开始倒计时
          _startCountdown();
          // 刷新验证码
          _loadCaptcha();
          _captchaCodeController.clear();
        } else {
          _showError('发送验证码失败');
          _loadCaptcha();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingSms = false;
        });
        _showError('发送验证码失败: ${e.toString()}');
        _loadCaptcha();
      }
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
        });
        return _countdown > 0;
      }
      return false;
    });
  }

  /// 邮箱登录
  Future<void> _handleEmailLogin() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final deviceId = StorageService.getDeviceId() ?? 
        DateTime.now().millisecondsSinceEpoch.toString();
    await StorageService.saveDeviceId(deviceId);
    
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      deviceId: deviceId,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      _showError(authProvider.errorMessage!);
    }
  }

  /// 手机号登录
  Future<void> _handleMobileLogin() async {
    if (_mobileController.text.trim().isEmpty) {
      _showError('请输入手机号');
      return;
    }
    
    if (_smsCodeController.text.trim().isEmpty) {
      _showError('请输入短信验证码');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final deviceId = StorageService.getDeviceId() ?? 
        DateTime.now().millisecondsSinceEpoch.toString();
    await StorageService.saveDeviceId(deviceId);
    
    final success = await authProvider.loginWithMobile(
      mobile: _mobileController.text.trim(),
      captcha: _smsCodeController.text.trim(),
      deviceId: deviceId,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else if (mounted && authProvider.errorMessage != null) {
      _showError(authProvider.errorMessage!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 解析 Base64 图片
  Uint8List? _decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    
    try {
      // 移除 data:image/png;base64, 前缀
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',')[1];
      }
      return base64Decode(base64Data);
    } catch (e) {
      print('解析Base64图片失败: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 标题区域
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '云湖',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '连接你我，沟通无限',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            // Tab 栏
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '手机号登录'),
                Tab(text: '邮箱登录'),
              ],
            ),
            
            // 内容区域
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 手机号登录
                  _buildMobileLoginForm(),
                  // 邮箱登录
                  _buildEmailLoginForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 手机号登录表单
  Widget _buildMobileLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _mobileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // 手机号输入框
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '手机号',
                hintText: '请输入手机号',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入手机号';
                }
                if (value.length != 11) {
                  return '请输入11位手机号';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 图片验证码
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _captchaCodeController,
                    decoration: InputDecoration(
                      labelText: '图片验证码',
                      hintText: '请输入验证码',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入图片验证码';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 验证码图片
                GestureDetector(
                  onTap: _loadCaptcha,
                  child: Container(
                    width: 250,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoadingCaptcha
                        ? const Center(child: CircularProgressIndicator())
                        : _captchaImageBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _decodeBase64Image(_captchaImageBase64)!,
                                  fit: BoxFit.cover,
                                  width: 230,
                                  height: 60,
                                ),
                              )
                            : const Center(child: Icon(Icons.refresh)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 短信验证码
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _smsCodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '短信验证码',
                      hintText: '请输入短信验证码',
                      prefixIcon: const Icon(Icons.message),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入短信验证码';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: (_countdown > 0 || _isSendingSms) ? null : _sendSmsCode,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSendingSms
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_countdown > 0 ? '${_countdown}秒' : '获取验证码'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // 登录按钮
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleMobileLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            '登录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 邮箱登录表单
  Widget _buildEmailLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // 邮箱输入框
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: '邮箱',
                hintText: '请输入邮箱地址',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入邮箱地址';
                }
                if (!value.contains('@')) {
                  return '请输入有效的邮箱地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 密码输入框
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '请输入密码',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6) {
                  return '密码至少6位';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // 登录按钮
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleEmailLogin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            '登录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
