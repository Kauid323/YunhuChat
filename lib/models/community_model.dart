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

  CommunityPartition({
    required this.id,
    required this.name,
    required this.avatar,
    required this.memberNum,
    required this.postNum,
  });

  factory CommunityPartition.fromJson(Map<String, dynamic> json) {
    return CommunityPartition(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      memberNum: json['memberNum'] ?? 0,
      postNum: json['postNum'] ?? 0,
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
