/// API配置文件
class ApiConfig {
  // 基础URL
  static const String baseUrl = 'https://chat-go.jwzhd.com';
  
  // WebSocket URL
  static const String wsUrl = 'wss://chat-ws-go.jwzhd.com/ws';
  
  // API版本
  static const String apiVersion = '/v1';
  
  // API端点
  static const String userEmailLogin = '$apiVersion/user/email-login';
  static const String userCaptcha = '$apiVersion/user/captcha';
  static const String userVerificationLogin = '$apiVersion/user/verification-login';
  static const String userInfo = '$apiVersion/user/info';
  static const String getUser = '$apiVersion/user/get-user';
  static const String conversationList = '$apiVersion/conversation/list';
  static const String listMessage = '$apiVersion/msg/list-message';
  static const String sendMessage = '$apiVersion/msg/send-message';
  static const String groupInfo = '$apiVersion/group/info';
  static const String listMember = '$apiVersion/group/list-member';
  static const String getVerificationCode = '$apiVersion/verification/get-verification-code';
  
  // 社区API端点
  static const String communityPostList = '$apiVersion/community/posts/post-list';
  static const String communityPartitionList = '$apiVersion/community/ba/following-ba-list';
  static const String communityPostCreate = '$apiVersion/community/posts/create';
  static const String communityPostDetail = '$apiVersion/community/posts/post-detail';
  static const String communityComment = '$apiVersion/community/comment/comment';
  static const String communityPostLike = '$apiVersion/community/posts/post-like';
  static const String communityPostCollect = '$apiVersion/community/posts/post-collect';
  static const String communityMyPostList = '$apiVersion/community/posts/my-post-list';
  static const String communityCommentList = '$apiVersion/community/comment/comment-list';
  static const String communityPartitionInfo = '$apiVersion/community/ba/info';
  static const String communityPartitionGroupList = '$apiVersion/community/ba/group-list';
  static const String communityFollowPartition = '$apiVersion/community/ba/user-follow-ba';
  static const String communityUnfollowPartition = '$apiVersion/community/ba/user-unfollow-ba';
  
  // 超时配置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // 心跳间隔
  static const Duration heartbeatInterval = Duration(seconds: 30);
}

/// 聊天类型映射
class ChatType {
  static const int user = 1;
  static const int group = 2;
  static const int bot = 3;
  
  static String getName(int type) {
    switch (type) {
      case user:
        return '用户';
      case group:
        return '群组';
      case bot:
        return '机器人';
      default:
        return '未知';
    }
  }
}

/// 内容类型映射
class ContentType {
  static const int text = 1;
  static const int image = 2;
  static const int markdown = 3;
  static const int file = 4;
  static const int form = 5;
  static const int post = 6;
  static const int sticker = 7;
  static const int html = 8;
  static const int audio = 11;
  static const int call = 13;
  
  static String getName(int type) {
    switch (type) {
      case text:
        return '文本';
      case image:
        return '图片';
      case markdown:
        return 'Markdown';
      case file:
        return '文件';
      case form:
        return '表单';
      case post:
        return '文章';
      case sticker:
        return '表情';
      case html:
        return 'HTML';
      case audio:
        return '语音';
      case call:
        return '通话';
      default:
        return '未知';
    }
  }
}

