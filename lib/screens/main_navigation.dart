import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'conversation_list_screen.dart';
import 'conversation_split_screen.dart';
import 'discover_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'contact_list_screen.dart';
import '../providers/settings_provider.dart';

/// 主导航页面（带底部导航栏）
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  double _railWidth = 80;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _pageForKey(String key) {
    switch (key) {
      case 'conversation':
        return const ConversationListScreen();
      case 'community':
        return const CommunityScreen();
      case 'contacts':
        return const ContactListScreen();
      case 'discover':
        return const DiscoverScreen();
      case 'profile':
        return const ProfileScreen();
      default:
        return const ConversationListScreen();
    }
  }

  NavigationRailDestination _railDestinationForKey(String key) {
    final dest = _destinationForKey(key);
    return NavigationRailDestination(
      icon: dest.icon,
      selectedIcon: dest.selectedIcon,
      label: Text(dest.label),
    );
  }

  NavigationDestination _destinationForKey(String key) {
    switch (key) {
      case 'conversation':
        return const NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: '会话',
        );
      case 'community':
        return const NavigationDestination(
          icon: Icon(Icons.forum_outlined),
          selectedIcon: Icon(Icons.forum),
          label: '社区',
        );
      case 'contacts':
        return const NavigationDestination(
          icon: Icon(Icons.contacts_outlined),
          selectedIcon: Icon(Icons.contacts),
          label: '通讯录',
        );
      case 'discover':
        return const NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: '发现',
        );
      case 'profile':
        return const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '我的',
        );
      default:
        return const NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: '会话',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    var navKeys = context.watch<SettingsProvider>().bottomNavItems;
    if (navKeys.length < 2) {
      navKeys = const <String>['conversation', 'community', 'contacts', 'discover', 'profile'];
    }

    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isTablet = size.shortestSide >= 600;
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final useRail = isTablet || (isLandscape && size.width >= 720);

    // 横屏/宽屏时使用会话分栏（列表 + 右侧聊天），不局限于 Windows
    final useConversationSplit = isLandscape && size.width >= 720;

    final maxRailWidth = (size.width * 0.45).clamp(240.0, 420.0);
    final minRailWidth = 72.0;

    final pages = navKeys.map((key) {
      if (key == 'conversation' && useConversationSplit) {
        return const ConversationSplitScreen();
      }
      return _pageForKey(key);
    }).toList();
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_selectedIndex);
        }
      });
    }

    final pageView = PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (!mounted) return;
        setState(() {
          _selectedIndex = index;
        });
      },
      children: pages,
    );

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: isWindows ? _railWidth.clamp(minRailWidth, maxRailWidth) : null,
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                extended: (isWindows ? _railWidth : size.width).toDouble() >= 220,
                labelType: (isWindows ? _railWidth : size.width).toDouble() >= 220
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.selected,
                destinations: navKeys.map(_railDestinationForKey).toList(),
              ),
            ),
            if (isWindows)
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _railWidth = (_railWidth + details.delta.dx)
                          .clamp(minRailWidth, maxRailWidth);
                    });
                  },
                  child: Container(
                    width: 6,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Container(
                      width: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              )
            else
              const VerticalDivider(width: 1),
            Expanded(child: pageView),
          ],
        ),
      );
    }

    return Scaffold(
      body: pageView,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        // Material 3 底部导航栏
        destinations: navKeys.map(_destinationForKey).toList(),
      ),
    );
  }
}

