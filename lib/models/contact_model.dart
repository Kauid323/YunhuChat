class AddressBookGroup {
  final String listName;
  final List<AddressBookItem> items;

  AddressBookGroup({
    required this.listName,
    required this.items,
  });

  factory AddressBookGroup.fromJson(Map<String, dynamic> json) {
    return AddressBookGroup(
      listName: json['list_name'] ?? '',
      items: (json['data'] as List<dynamic>?)
              ?.map((e) => AddressBookItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'list_name': listName,
      'data': items.map((e) => e.toJson()).toList(),
    };
  }
}

class AddressBookItem {
  final String chatId;
  final String name;
  final String avatarUrl;
  final int permissionLevel;
  final bool noDisturb;

  AddressBookItem({
    required this.chatId,
    required this.name,
    required this.avatarUrl,
    required this.permissionLevel,
    required this.noDisturb,
  });

  factory AddressBookItem.fromJson(Map<String, dynamic> json) {
    return AddressBookItem(
      chatId: json['chat_id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      permissionLevel: json['permission_level'] ?? 0,
      noDisturb: json['no_disturb'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'name': name,
      'avatar_url': avatarUrl,
      'permission_level': permissionLevel,
      'no_disturb': noDisturb,
    };
  }
}
