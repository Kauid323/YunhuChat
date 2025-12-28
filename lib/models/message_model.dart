/// 消息发送者模型
class MessageSender {
  final String chatId;
  final int chatType;
  final String name;
  final String? avatarUrl;
  final List<String>? tagOld;

  MessageSender({
    required this.chatId,
    required this.chatType,
    required this.name,
    this.avatarUrl,
    this.tagOld,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      chatId: json['chat_id']?.toString() ?? json['chatId']?.toString() ?? '',
      chatType: json['chat_type'] ?? json['chatType'] ?? 1,
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      tagOld: json['tag_old'] != null 
          ? List<String>.from(json['tag_old']) 
          : (json['tagOld'] != null ? List<String>.from(json['tagOld']) : null),
    );
  }
}

/// 消息内容模型
class MessageContent {
  final String? text;
  final String? imageUrl;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? videoUrl;
  final String? audioUrl;
  final int? audioTime;
  final String? quoteMsgText;

  MessageContent({
    this.text,
    this.imageUrl,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.videoUrl,
    this.audioUrl,
    this.audioTime,
    this.quoteMsgText,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      text: json['text']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      fileName: json['file_name']?.toString() ?? json['fileName']?.toString(),
      fileUrl: json['file_url']?.toString() ?? json['fileUrl']?.toString(),
      fileSize: json['file_size'] ?? json['fileSize'],
      videoUrl: json['video_url']?.toString() ?? json['videoUrl']?.toString(),
      audioUrl: json['audio_url']?.toString() ?? json['audioUrl']?.toString(),
      audioTime: json['audio_time'] ?? json['audioTime'],
      quoteMsgText: json['quote_msg_text']?.toString() ?? json['quoteMsgText']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (text != null) data['text'] = text;
    if (imageUrl != null) data['image'] = imageUrl;
    if (fileName != null) data['file_name'] = fileName;
    if (fileUrl != null) data['file_key'] = fileUrl;
    if (fileSize != null) data['file_size'] = fileSize;
    if (videoUrl != null) data['video'] = videoUrl;
    if (audioUrl != null) data['audio'] = audioUrl;
    if (audioTime != null) data['audio_time'] = audioTime;
    if (quoteMsgText != null) data['quote_msg_text'] = quoteMsgText;
    return data;
  }
}

/// 消息模型
class MessageModel {
  final String msgId;
  final MessageSender sender;
  final String? direction;
  final int contentType;
  final MessageContent content;
  final int? sendTime;
  final int? msgSeq;
  final int? editTime;
  final String? quoteMsgId;

  MessageModel({
    required this.msgId,
    required this.sender,
    this.direction,
    required this.contentType,
    required this.content,
    this.sendTime,
    this.msgSeq,
    this.editTime,
    this.quoteMsgId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      msgId: json['msg_id']?.toString() ?? json['msgId']?.toString() ?? '',
      sender: MessageSender.fromJson(json['sender'] ?? {}),
      direction: json['direction']?.toString(),
      contentType: json['content_type'] ?? json['contentType'] ?? 1,
      content: MessageContent.fromJson(json['content'] ?? {}),
      sendTime: json['send_time'] ?? json['sendTime'],
      msgSeq: json['msg_seq'] ?? json['msgSeq'],
      editTime: json['edit_time'] ?? json['editTime'],
      quoteMsgId: json['quote_msg_id']?.toString() ?? json['quoteMsgId']?.toString(),
    );
  }

  bool get isMyMessage => direction == 'right';

  String get contentTypeText {
    switch (contentType) {
      case 1:
        return '文本';
      case 2:
        return '图片';
      case 3:
        return 'Markdown';
      case 4:
        return '文件';
      case 10:
        return '视频';
      default:
        return '未知';
    }
  }
}

