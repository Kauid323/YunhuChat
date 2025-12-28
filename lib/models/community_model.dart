class CommunityPost {
  final int id;
  final int baId;
  final String senderId;
  final String title;
  final String content; // 预览内容
  final int contentType;
  final String senderNickname;
  final String senderAvatar;
  final int likeNum;
  final int commentNum;
  final int collectNum;
  final String createTimeText;
  final bool isLiked;
  final bool isCollected;

  CommunityPost({
    required this.id,
    required this.baId,
    required this.senderId,
    required this.title,
    required this.content,
    required this.contentType,
    required this.senderNickname,
    required this.senderAvatar,
    required this.likeNum,
    required this.commentNum,
    required this.collectNum,
    required this.createTimeText,
    this.isLiked = false,
    this.isCollected = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? 0,
      baId: json['baId'] ?? 0,
      senderId: json['senderId']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      contentType: json['contentType'] ?? 1,
      senderNickname: json['senderNickname'] ?? '',
      senderAvatar: json['senderAvatar'] ?? '',
      likeNum: json['likeNum'] ?? 0,
      commentNum: json['commentNum'] ?? 0,
      collectNum: json['collectNum'] ?? 0,
      createTimeText: json['createTimeText'] ?? '',
      isLiked: (json['isLiked'].toString() == '1'),
      isCollected: (json['isCollected'].toString() == '1' || json['isCollected'] == 1),
    );
  }
}

class CommunityPostDetailData {
  final CommunityPost post;
  final CommunityPartition ba;
  final int isAdmin;

  CommunityPostDetailData({
    required this.post,
    required this.ba,
    required this.isAdmin,
  });

  factory CommunityPostDetailData.fromJson(Map<String, dynamic> json) {
    return CommunityPostDetailData(
      post: CommunityPost.fromJson(json['post'] ?? {}),
      ba: CommunityPartition.fromJson(json['ba'] ?? {}),
      isAdmin: json['isAdmin'] ?? 0,
    );
  }
}

class CommunityPartition {
  final int id;
  final String name;
  final String avatar;
  final int memberNum;
  final int postNum;
  final int groupNum;
  final String createTimeText;
  final bool isFollowed;

  CommunityPartition({
    required this.id,
    required this.name,
    required this.avatar,
    required this.memberNum,
    required this.postNum,
    this.groupNum = 0,
    this.createTimeText = '',
    this.isFollowed = false,
  });

  factory CommunityPartition.fromJson(Map<String, dynamic> json) {
    return CommunityPartition(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      memberNum: json['memberNum'] ?? 0,
      postNum: json['postNum'] ?? 0,
      groupNum: json['groupNum'] ?? 0,
      createTimeText: json['createTimeText'] ?? '',
      isFollowed: (json['isFollowed'].toString() == '1'),
    );
  }
}

class CommunityComment {
  final int id;
  final int postId;
  final String senderId;
  final String content;
  final String senderNickname;
  final String senderAvatar;
  final String createTimeText;

  CommunityComment({
    required this.id,
    required this.postId,
    required this.senderId,
    required this.content,
    required this.senderNickname,
    required this.senderAvatar,
    required this.createTimeText,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] ?? 0,
      postId: json['postId'] ?? 0,
      senderId: json['senderId']?.toString() ?? '',
      content: json['content'] ?? '',
      senderNickname: json['senderNickname'] ?? '',
      senderAvatar: json['senderAvatar'] ?? '',
      createTimeText: json['createTimeText'] ?? '',
    );
  }
}

class CommunityGroup {
  final int id;
  final String groupId;
  final String name;
  final String introduction;
  final String avatarUrl;
  final int headcount;
  final String category;

  CommunityGroup({
    required this.id,
    required this.groupId,
    required this.name,
    required this.introduction,
    required this.avatarUrl,
    required this.headcount,
    required this.category,
  });

  factory CommunityGroup.fromJson(Map<String, dynamic> json) {
    return CommunityGroup(
      id: json['id'] ?? 0,
      groupId: json['groupId']?.toString() ?? '',
      name: json['name'] ?? '',
      introduction: json['introduction'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      headcount: json['headcount'] ?? 0,
      category: json['category'] ?? '',
    );
  }
}

class CommunitySearchResult {
  final List<CommunityPartition> partitions;
  final List<CommunityPost> posts;

  CommunitySearchResult({
    required this.partitions,
    required this.posts,
  });

  factory CommunitySearchResult.fromJson(Map<String, dynamic> json) {
    final bas = (json['ba'] as List?) ?? const [];
    final posts = (json['posts'] as List?) ?? const [];
    return CommunitySearchResult(
      partitions: bas.map((e) => CommunityPartition.fromJson(e)).toList(),
      posts: posts.map((e) => CommunityPost.fromJson(e)).toList(),
    );
  }
}
