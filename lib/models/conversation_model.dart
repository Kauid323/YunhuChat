/// 会话模型
class ConversationModel {
  final String chatId;
  final int chatType;
  final String name;
  final String? chatContent;
  final int? timestampMs;
  final int? unreadMessage;
  final int? at;
  final int? avatarId;
  final String? avatarUrl;
  final int? doNotDisturb;
  final int? timestamp;
  final int? certificationLevel;

  ConversationModel({
    required this.chatId,
    required this.chatType,
    required this.name,
    this.chatContent,
    this.timestampMs,
    this.unreadMessage,
    this.at,
    this.avatarId,
    this.avatarUrl,
    this.doNotDisturb,
    this.timestamp,
    this.certificationLevel,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      chatId: json['chat_id']?.toString() ?? json['chatId']?.toString() ?? '',
      chatType: json['chat_type'] ?? json['chatType'] ?? 1,
      name: json['name']?.toString() ?? '',
      chatContent: json['chat_content']?.toString() ?? json['chatContent']?.toString(),
      timestampMs: json['timestamp_ms'] ?? json['timestampMs'],
      unreadMessage: json['unread_message'] ?? json['unreadMessage'],
      at: json['at'],
      avatarId: json['avatar_id'] ?? json['avatarId'],
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      doNotDisturb: json['do_not_disturb'] ?? json['doNotDisturb'],
      timestamp: json['timestamp'],
      certificationLevel: json['certification_level'] ?? json['certificationLevel'],
    );
  }

  String get chatTypeText {
    switch (chatType) {
      case 1:
        return '用户';
      case 2:
        return '群组';
      case 3:
        return '机器人';
      default:
        return '未知';
    }
  }

  bool get hasUnread => (unreadMessage ?? 0) > 0;
}

