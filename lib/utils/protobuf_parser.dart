import 'dart:convert';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';

/// Protobuf 解析器
/// 手动实现 Protobuf Wire Format 解析
class ProtobufParser {
  final Uint8List _data;
  int _position = 0;

  ProtobufParser(this._data);

  /// 读取 varint (可变长度整数)
  Int64? readVarint() {
    if (_position >= _data.length) return null;
    
    Int64 result = Int64.ZERO;
    int shift = 0;
    
    while (_position < _data.length) {
      int byte = _data[_position++];
      result = result | (Int64(byte & 0x7F) << shift);
      
      if ((byte & 0x80) == 0) {
        return result;
      }
      
      shift += 7;
      if (shift > 63) {
        throw Exception('Varint 太长');
      }
    }
    
    return null;
  }

  /// 读取字段标签和类型
  (int, int)? readTag() {
    final value = readVarint();
    if (value == null) return null;
    
    final fieldNumber = (value.toInt() >> 3);
    final wireType = (value.toInt() & 0x07);
    
    return (fieldNumber, wireType);
  }

  /// 读取长度限定的数据
  Uint8List? readLengthDelimited() {
    final length = readVarint();
    if (length == null || _position + length.toInt() > _data.length) {
      return null;
    }
    
    final result = _data.sublist(_position, _position + length.toInt());
    _position += length.toInt();
    return result;
  }

  /// 读取字符串
  String? readString() {
    final bytes = readLengthDelimited();
    if (bytes == null) return null;
    
    try {
      // 使用UTF-8解码，支持中文
      return utf8.decode(bytes);
    } catch (e) {
      // 如果UTF-8解码失败，尝试使用默认编码
      try {
        return String.fromCharCodes(bytes);
      } catch (e2) {
        print('字符串解码失败: $e2');
        return null;
      }
    }
  }

  /// 读取 double (64位浮点数)
  double? readDouble() {
    if (_position + 8 > _data.length) return null;
    
    final bytes = _data.sublist(_position, _position + 8);
    _position += 8;
    
    // 小端序
    final buffer = ByteData(8);
    for (int i = 0; i < 8; i++) {
      buffer.setUint8(i, bytes[i]);
    }
    return buffer.getFloat64(0, Endian.little);
  }

  /// 读取 int32 (32位整数)
  int? readInt32() {
    if (_position + 4 > _data.length) return null;
    
    final buffer = ByteData(4);
    for (int i = 0; i < 4; i++) {
      buffer.setUint8(i, _data[_position + i]);
    }
    _position += 4;
    return buffer.getInt32(0, Endian.little);
  }

  /// 读取 int64 (64位整数)
  Int64? readInt64() {
    if (_position + 8 > _data.length) return null;
    
    final buffer = ByteData(8);
    for (int i = 0; i < 8; i++) {
      buffer.setUint8(i, _data[_position + i]);
    }
    _position += 8;
    return Int64(buffer.getInt64(0, Endian.little));
  }

  /// 跳过字段
  void skipField(int wireType) {
    switch (wireType) {
      case 0: // varint
        readVarint();
        break;
      case 1: // fixed64
        _position += 8;
        break;
      case 2: // length-delimited
        readLengthDelimited();
        break;
      case 5: // fixed32
        _position += 4;
        break;
      default:
        break;
    }
  }

  bool get hasMore => _position < _data.length;
  int get position => _position;
  void setPosition(int pos) => _position = pos;
}

/// 解析用户信息 Protobuf
Map<String, dynamic>? parseUserInfo(Uint8List data) {
  try {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    Status? status;
    Map<String, dynamic>? userData;

    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;

      final (fieldNumber, wireType) = tag;

      switch (fieldNumber) {
        case 1: // status
          final statusData = parser.readLengthDelimited();
          if (statusData != null) {
            status = parseStatus(statusData);
            result['status'] = status?.toMap();
          }
          break;
        case 2: // data
          final dataBytes = parser.readLengthDelimited();
          if (dataBytes != null) {
            userData = parseUserInfoData(dataBytes);
            result['data'] = userData;
          }
          break;
        default:
          parser.skipField(wireType);
      }
    }

    if (status != null && userData != null) {
      return result;
    }
    return null;
  } catch (e) {
    print('解析用户信息失败: $e');
    return null;
  }
}

/// 解析 Status
class Status {
  final Int64? number;
  final int? code;
  final String? msg;

  Status({this.number, this.code, this.msg});

  Map<String, dynamic> toMap() {
    return {
      'number': number?.toInt(),
      'code': code,
      'msg': msg,
    };
  }
}

Status? parseStatus(Uint8List data) {
  final parser = ProtobufParser(data);
  Int64? number;
  int? code;
  String? msg;

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // number
        number = parser.readVarint();
        break;
      case 2: // code
        code = parser.readVarint()?.toInt();
        break;
      case 3: // msg
        msg = parser.readString();
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return Status(number: number, code: code, msg: msg);
}

/// 解析用户信息数据
Map<String, dynamic> parseUserInfoData(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // id
        final id = parser.readString();
        if (id != null) result['id'] = id;
        break;
      case 2: // name
        final name = parser.readString();
        if (name != null) {
          result['name'] = name;
          print('解析到名称: $name (长度: ${name.length})');
        } else {
          print('名称字段为空');
        }
        break;
      case 4: // avatar_url
        final avatarUrl = parser.readString();
        if (avatarUrl != null) result['avatar_url'] = avatarUrl;
        break;
      case 5: // avatar_id
        final avatarId = parser.readVarint();
        if (avatarId != null) result['avatar_id'] = avatarId.toInt();
        break;
      case 6: // phone
        final phone = parser.readString();
        if (phone != null) result['phone'] = phone;
        break;
      case 7: // email
        final email = parser.readString();
        if (email != null) result['email'] = email;
        break;
      case 8: // coin
        final coin = parser.readDouble();
        if (coin != null) result['coin'] = coin;
        break;
      case 9: // is_vip
        final isVip = parser.readVarint();
        if (isVip != null) result['is_vip'] = isVip.toInt();
        break;
      case 10: // vip_expired_time
        final vipExpiredTime = parser.readVarint();
        if (vipExpiredTime != null) result['vip_expired_time'] = vipExpiredTime.toInt();
        break;
      case 12: // invitation_code
        final invitationCode = parser.readString();
        if (invitationCode != null) result['invitation_code'] = invitationCode;
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return result;
}

/// 解析会话列表 Protobuf
Map<String, dynamic>? parseConversationList(Uint8List data) {
  try {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    Status? status;
    List<Map<String, dynamic>>? conversationList;

    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;

      final (fieldNumber, wireType) = tag;

      switch (fieldNumber) {
        case 1: // status
          final statusData = parser.readLengthDelimited();
          if (statusData != null) {
            status = parseStatus(statusData);
            result['status'] = status?.toMap();
          }
          break;
        case 2: // data (repeated ConversationData)
          final dataBytes = parser.readLengthDelimited();
          if (dataBytes != null) {
            if (conversationList == null) {
              conversationList = [];
            }
            final conversationData = parseConversationData(dataBytes);
            conversationList.add(conversationData);
          }
          break;
        default:
          parser.skipField(wireType);
      }
    }

    if (conversationList != null) {
      result['data'] = conversationList;
    }

    if (status != null) {
      return result;
    }
    return null;
  } catch (e) {
    print('解析会话列表失败: $e');
    return null;
  }
}

/// 解析单个会话数据
Map<String, dynamic> parseConversationData(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // chat_id
        result['chat_id'] = parser.readString() ?? '';
        break;
      case 2: // chat_type
        result['chat_type'] = parser.readVarint()?.toInt() ?? 1;
        break;
      case 3: // name
        result['name'] = parser.readString() ?? '';
        break;
      case 4: // chat_content
        result['chat_content'] = parser.readString();
        break;
      case 5: // timestamp_ms
        result['timestamp_ms'] = parser.readVarint()?.toInt();
        break;
      case 6: // unread_message
        result['unread_message'] = parser.readVarint()?.toInt();
        break;
      case 7: // at
        result['at'] = parser.readVarint()?.toInt();
        break;
      case 8: // avatar_id
        result['avatar_id'] = parser.readVarint()?.toInt();
        break;
      case 9: // avatar_url
        result['avatar_url'] = parser.readString();
        break;
      case 11: // do_not_disturb
        result['do_not_disturb'] = parser.readVarint()?.toInt();
        break;
      case 12: // timestamp
        result['timestamp'] = parser.readVarint()?.toInt();
        break;
      case 16: // certification_level
        result['certification_level'] = parser.readVarint()?.toInt();
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return result;
}

/// 解析消息列表 Protobuf
Map<String, dynamic>? parseMessageList(Uint8List data) {
  try {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    Status? status;
    List<Map<String, dynamic>>? msgList;

    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;

      final (fieldNumber, wireType) = tag;

      switch (fieldNumber) {
        case 1: // status
          final statusData = parser.readLengthDelimited();
          if (statusData != null) {
            status = parseStatus(statusData);
            result['status'] = status?.toMap();
          }
          break;
        case 2: // msg (repeated Msg)
          final msgBytes = parser.readLengthDelimited();
          if (msgBytes != null) {
            if (msgList == null) {
              msgList = [];
            }
            final msgData = parseMessageData(msgBytes);
            msgList.add(msgData);
          }
          break;
        default:
          parser.skipField(wireType);
      }
    }

    if (msgList != null) {
      result['msg'] = msgList;
    }

    if (status != null) {
      return result;
    }
    return null;
  } catch (e) {
    print('解析消息列表失败: $e');
    return null;
  }
}

/// 解析单个消息数据（简化版，只解析主要字段）
Map<String, dynamic> parseMessageData(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};
  Map<String, dynamic>? sender;
  Map<String, dynamic>? content;

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // msg_id
        result['msg_id'] = parser.readString() ?? '';
        break;
      case 2: // sender
        final senderBytes = parser.readLengthDelimited();
        if (senderBytes != null) {
          sender = parseMessageSender(senderBytes);
          result['sender'] = sender;
        }
        break;
      case 3: // direction
        result['direction'] = parser.readString();
        break;
      case 4: // content_type
        result['content_type'] = parser.readVarint()?.toInt() ?? 1;
        break;
      case 5: // content
        final contentBytes = parser.readLengthDelimited();
        if (contentBytes != null) {
          content = parseMessageContent(contentBytes);
          result['content'] = content;
        }
        break;
      case 6: // send_time
        result['send_time'] = parser.readVarint()?.toInt();
        break;
      case 10: // msg_seq
        result['msg_seq'] = parser.readVarint()?.toInt();
        break;
      case 12: // edit_time
        result['edit_time'] = parser.readVarint()?.toInt();
        break;
      case 9: // quote_msg_id
        result['quote_msg_id'] = parser.readString();
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return result;
}

/// 解析消息发送者
Map<String, dynamic> parseMessageSender(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // chat_id
        result['chat_id'] = parser.readString() ?? '';
        break;
      case 2: // chat_type
        result['chat_type'] = parser.readVarint()?.toInt() ?? 1;
        break;
      case 3: // name
        result['name'] = parser.readString() ?? '';
        break;
      case 4: // avatar_url
        result['avatar_url'] = parser.readString();
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return result;
}

/// 解析消息内容
Map<String, dynamic> parseMessageContent(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // text
        result['text'] = parser.readString();
        break;
      case 3: // image_url
        result['image_url'] = parser.readString();
        break;
      case 4: // file_name
        result['file_name'] = parser.readString();
        break;
      case 5: // file_url
        result['file_url'] = parser.readString();
        break;
      case 8: // quote_msg_text
        result['quote_msg_text'] = parser.readString();
        break;
      case 18: // file_size
        result['file_size'] = parser.readVarint()?.toInt();
        break;
      case 19: // video_url
        result['video_url'] = parser.readString();
        break;
      case 21: // audio_url
        result['audio_url'] = parser.readString();
        break;
      case 22: // audio_time
        result['audio_time'] = parser.readVarint()?.toInt();
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return result;
}

/// 解析 Medal_info
Map<String, dynamic>? parseMedalInfo(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // id
        result['id'] = parser.readVarint()?.toInt();
        break;
      case 2: // name
        result['name'] = parser.readString();
        break;
      case 5: // sort
        result['sort'] = parser.readVarint()?.toInt();
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return result;
}

/// 解析 RemarkInfo
Map<String, dynamic>? parseRemarkInfo(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // remark_name
        result['remark_name'] = parser.readString();
        break;
      case 2: // phone_number
        result['phone_number'] = parser.readString();
        break;
      case 3: // extra_remark
        result['extra_remark'] = parser.readString();
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return result;
}

/// 解析 ProfileInfo
Map<String, dynamic>? parseProfileInfo(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // last_active_time
        result['last_active_time'] = parser.readString();
        break;
      case 2: // introduction
        result['introduction'] = parser.readString();
        break;
      case 3: // gender
        result['gender'] = parser.readVarint()?.toInt();
        break;
      case 4: // birthday
        result['birthday'] = parser.readVarint()?.toInt();
        break;
      case 5: // city
        result['city'] = parser.readString();
        break;
      case 6: // district
        result['district'] = parser.readString();
        break;
      case 7: // address
        result['address'] = parser.readString();
        break;
      default:
        parser.skipField(wireType);
    }
  }

  return result;
}

/// 解析 get_user 响应
Map<String, dynamic>? parseGetUser(Uint8List data) {
  try {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    Status? status;
    Map<String, dynamic>? userData;

    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;

      final (fieldNumber, wireType) = tag;

      switch (fieldNumber) {
        case 1: // status
          final statusData = parser.readLengthDelimited();
          if (statusData != null) {
            status = parseStatus(statusData);
            result['status'] = status?.toMap();
          }
          break;
        case 2: // data
          final dataBytes = parser.readLengthDelimited();
          if (dataBytes != null) {
            userData = parseGetUserData(dataBytes);
            result['data'] = userData;
          }
          break;
        default:
          parser.skipField(wireType);
      }
    }

    if (status != null && userData != null) {
      return result;
    }
    return null;
  } catch (e) {
    print('解析用户详情失败: $e');
    return null;
  }
}

/// 解析 get_user Data
Map<String, dynamic> parseGetUserData(Uint8List data) {
  final parser = ProtobufParser(data);
  final result = <String, dynamic>{};
  final medals = <Map<String, dynamic>>[];

  while (parser.hasMore) {
    final tag = parser.readTag();
    if (tag == null) break;

    final (fieldNumber, wireType) = tag;

    switch (fieldNumber) {
      case 1: // id
        result['id'] = parser.readString();
        break;
      case 2: // name
        result['name'] = parser.readString();
        break;
      case 3: // name_id
        result['name_id'] = parser.readVarint()?.toInt();
        break;
      case 4: // avatar_url
        result['avatar_url'] = parser.readString();
        break;
      case 5: // avatar_id
        result['avatar_id'] = parser.readVarint()?.toInt();
        break;
      case 6: // medal (repeated)
        final medalData = parser.readLengthDelimited();
        if (medalData != null) {
          final medal = parseMedalInfo(medalData);
          if (medal != null) {
            medals.add(medal);
          }
        }
        break;
      case 7: // register_time
        result['register_time'] = parser.readString();
        break;
      case 10: // ban_time
        result['ban_time'] = parser.readVarint()?.toInt();
        break;
      case 11: // online_day
        result['online_day'] = parser.readVarint()?.toInt();
        break;
      case 12: // continuous_online_day
        result['continuous_online_day'] = parser.readVarint()?.toInt();
        break;
      case 13: // is_vip
        result['is_vip'] = parser.readVarint()?.toInt();
        break;
      case 14: // vip_expired_time
        result['vip_expired_time'] = parser.readVarint()?.toInt();
        break;
      case 18: // remark_info
        final remarkData = parser.readLengthDelimited();
        if (remarkData != null) {
          result['remark_info'] = parseRemarkInfo(remarkData);
        }
        break;
      case 19: // profile_info
        final profileData = parser.readLengthDelimited();
        if (profileData != null) {
          result['profile_info'] = parseProfileInfo(profileData);
        }
        break;
      default:
        parser.skipField(wireType);
    }
  }

  if (medals.isNotEmpty) {
    result['medal'] = medals;
  }

  return result;
}

