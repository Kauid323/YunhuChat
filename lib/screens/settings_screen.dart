import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _seedColorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _seedColorController.text = settings.seedColorHex;
  }

  @override
  void dispose() {
    _seedColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '底部导航栏',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _BottomNavSection(
            items: context.watch<SettingsProvider>().bottomNavItems,
            available: context.watch<SettingsProvider>().bottomNavAvailableItems,
            onReorder: context.read<SettingsProvider>().reorderBottomNavItems,
            onToggle: context.read<SettingsProvider>().toggleBottomNavItem,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '主题',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            title: const Text('主题色（ARGB 8位十六进制）'),
            subtitle: const Text('例如：#66CCFF / FF2196F3 / #FF2196F3 / 0xFF2196F3'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seedColorController,
                    decoration: const InputDecoration(
                      hintText: 'FF2196F3',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    final settings = context.read<SettingsProvider>();
                    final ok = await settings.setSeedColorHex(_seedColorController.text);
                    if (!context.mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('颜色格式不正确，必须是 8 位 ARGB 十六进制')),
                      );
                    }
                  },
                  child: const Text('应用'),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '连接',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final enabled = !auth.isWebsocketManuallyDisabled;
              return SwitchListTile(
                title: const Text('WebSocket 连接'),
                subtitle: const Text('手动关闭后将不会自动重连'),
                value: enabled,
                onChanged: (v) {
                  auth.setWebsocketEnabled(v);
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BottomNavSection extends StatelessWidget {
  final List<String> items;
  final List<String> available;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String item, bool enabled) onToggle;

  const _BottomNavSection({
    required this.items,
    required this.available,
    required this.onReorder,
    required this.onToggle,
  });

  String _label(String key) {
    switch (key) {
      case 'conversation':
        return '会话';
      case 'community':
        return '社区';
      case 'contacts':
        return '通讯录';
      case 'discover':
        return '发现';
      case 'profile':
        return '我的';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabledSet = items.toSet();
    final all = <String>[...items, ...available.where((a) => !enabledSet.contains(a))];
    final enabled = all.where((e) => enabledSet.contains(e)).toList();

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: all.length,
      onReorder: (oldIndex, newIndex) {
        final moving = all[oldIndex];
        if (!enabledSet.contains(moving)) {
          return;
        }

        final oldEnabledIndex = enabled.indexOf(moving);
        if (oldEnabledIndex < 0) return;

        var insertEnabledIndex = enabled.length;
        if (newIndex <= 0) {
          insertEnabledIndex = 0;
        } else if (newIndex >= all.length) {
          insertEnabledIndex = enabled.length;
        } else {
          final before = all[newIndex > oldIndex ? newIndex - 1 : newIndex];
          final beforeEnabledIndex = enabled.indexOf(before);
          if (beforeEnabledIndex >= 0) {
            insertEnabledIndex = beforeEnabledIndex + 1;
          } else {
            insertEnabledIndex = oldEnabledIndex;
          }
        }

        onReorder(oldEnabledIndex, insertEnabledIndex);
      },
      itemBuilder: (context, index) {
        final item = all[index];
        final enabled = enabledSet.contains(item);
        return SwitchListTile(
          key: ValueKey('bottom_$item'),
          title: Text(_label(item)),
          value: enabled,
          onChanged: (v) => onToggle(item, v),
          secondary: enabled ? const Icon(Icons.drag_handle) : null,
        );
      },
    );
  }
}
