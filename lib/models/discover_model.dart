class DiscoverGroupItem {
  final String chatId;
  final int banId;
  final String nickname;
  final String introduction;
  final String avatarUrl;
  final int headcount;
  final int createTime;

  DiscoverGroupItem({
    required this.chatId,
    required this.banId,
    required this.nickname,
    required this.introduction,
    required this.avatarUrl,
    required this.headcount,
    required this.createTime,
  });

  factory DiscoverGroupItem.fromJson(Map<String, dynamic> json) {
    return DiscoverGroupItem(
      chatId: json['chatId']?.toString() ?? json['chat_id']?.toString() ?? '',
      banId: json['banId'] ?? json['ban_id'] ?? 0,
      nickname: json['nickname']?.toString() ?? '',
      introduction: json['introduction']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString() ?? '',
      headcount: int.tryParse(json['headcount']?.toString() ?? '') ?? (json['headcount'] ?? 0),
      createTime: json['createTime'] ?? json['create_time'] ?? 0,
    );
  }
}

class DiscoverBotItem {
  final String chatId;
  final int chatType;
  final int headcount;
  final String nickname;
  final String introduction;
  final String avatarUrl;
  final int isAdd;
  final int isApply;
  final int alwaysAgree;

  DiscoverBotItem({
    required this.chatId,
    required this.chatType,
    required this.headcount,
    required this.nickname,
    required this.introduction,
    required this.avatarUrl,
    required this.isAdd,
    required this.isApply,
    required this.alwaysAgree,
  });

  factory DiscoverBotItem.fromJson(Map<String, dynamic> json) {
    return DiscoverBotItem(
      chatId: json['chatId']?.toString() ?? json['chat_id']?.toString() ?? '',
      chatType: int.tryParse(json['chatType']?.toString() ?? '') ?? (json['chat_type'] ?? 3),
      headcount: int.tryParse(json['headcount']?.toString() ?? '') ?? 0,
      nickname: json['nickname']?.toString() ?? '',
      introduction: json['introduction']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString() ?? '',
      isAdd: int.tryParse(json['isAdd']?.toString() ?? '') ?? (json['is_add'] ?? 0),
      isApply: int.tryParse(json['isApply']?.toString() ?? '') ?? (json['is_apply'] ?? 0),
      alwaysAgree: int.tryParse(json['alwaysAgree']?.toString() ?? '') ?? (json['always_agree'] ?? 0),
    );
  }
}

class DiscoverCategoryList {
  final List<String> categories;

  DiscoverCategoryList({required this.categories});

  factory DiscoverCategoryList.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final raw = data?['categories'];
    final list = raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
    return DiscoverCategoryList(categories: list);
  }
}
