import 'package:flutter/material.dart';

class FriendSettingsScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const FriendSettingsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(userName),
            subtitle: Text('ID: $userId'),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.edit),
            title: Text('修改备注'),
            subtitle: Text('未实现'),
          ),
          const ListTile(
            leading: Icon(Icons.notifications_off_outlined),
            title: Text('消息免打扰'),
            subtitle: Text('未实现'),
          ),
          const ListTile(
            leading: Icon(Icons.block),
            title: Text('拉黑 / 删除好友'),
            subtitle: Text('未实现'),
          ),
        ],
      ),
    );
  }
}
