import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/image_loader.dart';
import 'package:intl/intl.dart';

/// 用户详情页面
class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  Future<void> _loadUserDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getUserDetail(widget.userId);
      if (mounted) {
        setState(() {
          _userData = data?['data'];
          _isLoading = false;
          if (_userData == null) {
            _errorMessage = '获取用户信息失败';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载失败: ${e.toString()}';
        });
      }
    }
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '未知';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  String _formatRegisterTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '未知';
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户详情'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _userData == null
                  ? const Center(child: Text('用户信息为空'))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // 头像和基本信息
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  backgroundImage: _userData!['avatar_url'] != null
                                      ? ImageLoader.networkImageProvider(
                                          _userData!['avatar_url'].toString())
                                      : null,
                                  child: _userData!['avatar_url'] == null
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _userData!['name']?.toString() ?? '未知',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                ),
                                if (_userData!['name_id'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${_userData!['name_id']}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                                // VIP 标识
                                if (_userData!['is_vip'] == 1) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'VIP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 勋章
                          if (_userData!['medal'] != null &&
                              (_userData!['medal'] as List).isNotEmpty) ...[
                            _buildSection(
                              title: '勋章',
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (_userData!['medal'] as List)
                                    .map<Widget>((medal) => Chip(
                                          label: Text(medal['name']?.toString() ?? ''),
                                          avatar: Icon(Icons.workspace_premium, size: 16),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],

                          // 基本信息
                          _buildSection(
                            title: '基本信息',
                            child: Column(
                              children: [
                                _buildInfoRow('用户ID', _userData!['id']?.toString() ?? ''),
                                _buildInfoRow(
                                    '注册时间', _formatRegisterTime(_userData!['register_time']?.toString())),
                                if (_userData!['online_day'] != null)
                                  _buildInfoRow('在线天数', '${_userData!['online_day']} 天'),
                                if (_userData!['continuous_online_day'] != null)
                                  _buildInfoRow(
                                      '连续在线', '${_userData!['continuous_online_day']} 天'),
                                if (_userData!['is_vip'] == 1 && _userData!['vip_expired_time'] != null)
                                  _buildInfoRow('VIP到期', _formatTimestamp(_userData!['vip_expired_time'])),
                              ],
                            ),
                          ),

                          // 备注信息
                          if (_userData!['remark_info'] != null) ...[
                            _buildSection(
                              title: '备注信息',
                              child: Column(
                                children: [
                                  if (_userData!['remark_info']['remark_name'] != null)
                                    _buildInfoRow('备注名',
                                        _userData!['remark_info']['remark_name'].toString()),
                                  if (_userData!['remark_info']['phone_number'] != null)
                                    _buildInfoRow('手机号',
                                        _userData!['remark_info']['phone_number'].toString()),
                                ],
                              ),
                            ),
                          ],

                          // 个人资料
                          if (_userData!['profile_info'] != null) ...[
                            _buildSection(
                              title: '个人资料',
                              child: Column(
                                children: [
                                  if (_userData!['profile_info']['introduction'] != null)
                                    _buildInfoRow('简介',
                                        _userData!['profile_info']['introduction'].toString()),
                                  if (_userData!['profile_info']['gender'] != null) ...[
                                    _buildInfoRow(
                                      '性别',
                                      _userData!['profile_info']['gender'] == 1
                                          ? '男'
                                          : _userData!['profile_info']['gender'] == 2
                                              ? '女'
                                              : '其他',
                                    ),
                                  ],
                                  if (_userData!['profile_info']['city'] != null)
                                    _buildInfoRow('城市', _userData!['profile_info']['city'].toString()),
                                  if (_userData!['profile_info']['last_active_time'] != null)
                                    _buildInfoRow('最后活跃',
                                        _userData!['profile_info']['last_active_time'].toString()),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

