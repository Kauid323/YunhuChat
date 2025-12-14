import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化本地存储
  await StorageService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          // 状态栏样式
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          // 导航栏样式（手势条背景）
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return MaterialApp(
              title: '云湖',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: settings.seedColor,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: settings.seedColor,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              themeMode: ThemeMode.system,
              builder: (context, child) {
            // 根据主题动态设置系统 UI 样式
            final theme = Theme.of(context);
            final brightness = theme.brightness;
            // 使用与 NavigationBar 相同的背景色（Material 3 中 NavigationBar 使用 surface 颜色）
            final navigationBarColor = theme.colorScheme.surface;
            
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: brightness == Brightness.dark
                    ? Brightness.dark
                    : Brightness.light,
                // 使用与 NavigationBar 相同的颜色
                systemNavigationBarColor: navigationBarColor,
                systemNavigationBarIconBrightness: brightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
              child: child!,
            );
              },
              home: StorageService.isLoggedIn() ? const MainEntry() : const LoginScreen(),
            );
          },
        ),
      ),
    );
  }
}

/// 主入口封装，用于处理自动登录逻辑
class MainEntry extends StatefulWidget {
  const MainEntry({super.key});

  @override
  State<MainEntry> createState() => _MainEntryState();
}

class _MainEntryState extends State<MainEntry> {
  @override
  void initState() {
    super.initState();
    // 启动时在后台尝试更新用户信息和连接 WebSocket
    // 使用 addPostFrameCallback 避免在 build 过程中调用 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLogin();
    });
  }

  Future<void> _autoLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // 这里 autoLogin 会更新 User 信息
    await authProvider.autoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}
