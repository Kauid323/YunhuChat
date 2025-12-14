import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'conversation_list_screen.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

    final pages = navKeys.map(_pageForKey).toList();
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        // Material 3 底部导航栏
        destinations: navKeys.map(_destinationForKey).toList(),
      ),
    );
  }
}

