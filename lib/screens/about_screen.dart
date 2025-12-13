import 'package:flutter/material.dart';

/// 关于页面
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 应用信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 应用图标
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.chat,
                      size: 40,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 应用名称
                  Text(
                    'YunhuChat',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 版本号
                  Text(
                    '版本 1.0.1',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 开发者
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '开发者：那狗吧/Kauid323',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 介绍
                  Text(
                    '云湖flutter第三方',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 开源软件许可
          Text(
            '开源软件许可',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Card(
            child: Column(
              children: [
                _buildLicenseItem('Flutter', 'BSD-3-Clause'),
                _buildLicenseItem('provider', 'MIT'),
                _buildLicenseItem('http', 'BSD-3-Clause'),
                _buildLicenseItem('web_socket_channel', 'BSD-3-Clause'),
                _buildLicenseItem('shared_preferences', 'BSD-3-Clause'),
                _buildLicenseItem('json_annotation', 'BSD-3-Clause'),
                _buildLicenseItem('protobuf', 'BSD-3-Clause'),
                _buildLicenseItem('intl', 'BSD-3-Clause'),
                _buildLicenseItem('uuid', 'MIT'),
                _buildLicenseItem('cached_network_image', 'MIT'),
                _buildLicenseItem('markdown_widget', 'MIT'),
                _buildLicenseItem('markdown', 'BSD-3-Clause'),
                _buildLicenseItem('flutter_math_fork', 'Apache-2.0'),
                _buildLicenseItem('extended_image', 'MIT'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 版权信息
          Center(
            child: Text(
              '© 2024 那狗吧/Kauid323\n本应用为第三方客户端，与官方无关',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseItem(String name, String license) {
    return ListTile(
      title: Text(name),
      subtitle: Text(license),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}