import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/image_loader.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;

  const GroupInfoScreen({super.key, required this.groupId});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late Future<Map<String, dynamic>?> _future;

  static final Map<String, String> _labels = <String, String>{
    'group_id': '群聊ID',
    'name': '群聊名称',
    'avatar_url': '头像URL',
    'avatar_id': '头像ID',
    'introduction': '群聊简介',
    'member': '群人数',
    'create_by': '创建者ID',
    'direct_join': '进群免审核',
    'permisson_level': '我的权限等级',
    'history_msg': '历史消息',
    'category_name': '分类名',
    'category_id': '分类ID',
    'private': '是否私有',
    'do_not_disturb': '免打扰',
    'community_id': '社区ID',
    'community_name': '社区名称',
    'top': '置顶会话',
    'admin': '管理员ID',
    'limited_msg_type': '限制的消息类型',
    'owner': '群主ID',
    'recommandation': '加入群推荐',
    'tag_old': '标签(旧)',
    'tag': '标签',
    'my_group_nickname': '我的群昵称',
    'group_code': '群口令',
  };

  @override
  void initState() {
    super.initState();
    _future = ApiService.getGroupInfo(groupId: widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('群聊信息'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('加载失败'));
          }

          final status = data['status'];
          final group = data['data'];
          final historyBots = data['history_bot'];

          final statusCode = status is Map ? status['code'] : null;
          if (statusCode != 1) {
            final msg = status is Map ? (status['msg']?.toString() ?? '请求失败') : '请求失败';
            return Center(child: Text(msg));
          }

          final groupMap = group is Map ? Map<String, dynamic>.from(group.cast<dynamic, dynamic>()) : <String, dynamic>{};
          final avatarUrl = groupMap['avatar_url']?.toString();
          final name = groupMap['name']?.toString() ?? '';

          final primary = <String, dynamic>{};
          for (final k in <String>[
            'group_id',
            'introduction',
            'member',
            'category_name',
            'community_name',
            'my_group_nickname',
            'group_code',
            'owner',
            'create_by',
          ]) {
            if (groupMap.containsKey(k)) primary[k] = groupMap[k];
          }

          final switches = <String, dynamic>{};
          for (final k in <String>[
            'direct_join',
            'history_msg',
            'private',
            'do_not_disturb',
            'top',
            'recommandation',
          ]) {
            if (groupMap.containsKey(k)) switches[k] = groupMap[k];
          }

          final misc = <String, dynamic>{};
          for (final k in <String>[
            'permisson_level',
            'limited_msg_type',
            'admin',
            'tag',
            'tag_old',
            'community_id',
            'category_id',
            'avatar_id',
          ]) {
            if (groupMap.containsKey(k)) misc[k] = groupMap[k];
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (avatarUrl != null && avatarUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageLoader.networkImage(
                      url: avatarUrl,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _kvCard('基础信息', primary),
              if (switches.isNotEmpty) ...[
                const SizedBox(height: 16),
                _kvCard('开关设置', switches),
              ],
              if (misc.isNotEmpty) ...[
                const SizedBox(height: 16),
                _kvCard('其他信息', misc),
              ],
              const SizedBox(height: 16),
              _botsCard('历史机器人', historyBots),
            ],
          );
        },
      ),
    );
  }

  Widget _kvCard(String title, Map<String, dynamic> map) {
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        _labels[e.key] ?? e.key,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(child: _valueWidget(e.key, e.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _botsCard(String title, dynamic bots) {
    final list = bots is List ? bots : const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (list.isEmpty)
              Text('无', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
            else
              for (final item in list)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _botTile(item),
                ),
          ],
        ),
      ),
    );
  }

  Widget _botTile(dynamic item) {
    final m = item is Map ? Map<String, dynamic>.from(item.cast<dynamic, dynamic>()) : <String, dynamic>{};
    final avatarUrl = m['avatar_url']?.toString();
    final title = m['name']?.toString() ?? m['bot_id']?.toString() ?? '';
    final subtitle = m['introduction']?.toString() ?? '';
    final userNumber = m['headcount'] ?? m['user_number'];
    final createTime = m['create_time'];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: avatarUrl != null && avatarUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageLoader.networkImage(
                url: avatarUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            )
          : const SizedBox(width: 40, height: 40),
      title: Text(title.isEmpty ? '机器人' : title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle.isNotEmpty) Text(subtitle),
          if (userNumber != null || createTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _joinNonEmpty(<String>[
                  if (userNumber != null) '使用人数：${_stringify(userNumber)}',
                  if (createTime != null) '创建时间：${_formatTime(createTime)}',
                ]),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _valueWidget(String key, dynamic value) {
    if (key == 'tag' && value is List) {
      if (value.isEmpty) return const Text('无');
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: value.map<Widget>((e) {
          final m = e is Map ? Map<String, dynamic>.from(e.cast<dynamic, dynamic>()) : <String, dynamic>{};
          final text = m['text']?.toString() ?? '';
          final id = m['id']?.toString();
          final colorStr = m['color']?.toString();
          final color = _parseHexColor(colorStr);
          final label = text.isNotEmpty ? text : (id ?? '标签');
          return Chip(
            label: Text(label),
            backgroundColor: color?.withOpacity(0.18),
            side: color != null ? BorderSide(color: color.withOpacity(0.6)) : null,
          );
        }).toList(),
      );
    }

    if ((key == 'admin' || key == 'tag_old') && value is List) {
      if (value.isEmpty) return const Text('无');
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: value.map<Widget>((e) => Chip(label: Text(_stringify(e)))).toList(),
      );
    }

    if (key == 'permisson_level') {
      final v = _toInt(value);
      if (v == null) return Text(_stringify(value));
      final name = v == 100 ? '群主' : (v == 2 ? '管理员' : '普通成员');
      return Text('$name（$v）');
    }

    if (<String>{
      'direct_join',
      'history_msg',
      'private',
      'do_not_disturb',
      'top',
      'recommandation',
    }.contains(key)) {
      final v = _toInt(value);
      if (v == null) return Text(_stringify(value));
      return Text(v == 1 ? '开启' : '关闭');
    }

    if (key == 'limited_msg_type') {
      final s = value?.toString() ?? '';
      if (s.isEmpty) return const Text('无');
      return Text(s);
    }

    return Text(_stringify(value));
  }

  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  String _joinNonEmpty(List<String> parts) {
    final filtered = parts.where((e) => e.trim().isNotEmpty).toList();
    return filtered.join('  ');
  }

  String _formatTime(dynamic v) {
    final n = _toInt(v);
    if (n == null) return _stringify(v);
    final ms = n > 1000000000000 ? n : n * 1000;
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return _stringify(v);
    }
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null) return null;
    var s = hex.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final value = int.tryParse(s, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  String _stringify(dynamic v) {
    if (v == null) return 'null';
    if (v is List) return v.map(_stringify).join(', ');
    if (v is Map) {
      final entries = v.entries.map((e) => '${e.key}: ${_stringify(e.value)}').join(', ');
      return '{ $entries }';
    }
    return v.toString();
  }
}
