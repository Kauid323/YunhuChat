import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'protobuf_parser.dart';

/// 解析WebSocket Protobuf消息
class WebSocketProtobufParser {
  /// 解析push_message（推送消息）
  static Map<String, dynamic>? parsePushMessage(Uint8List data) {
    try {
      final parser = ProtobufParser(data);
      final result = <String, dynamic>{};
      Map<String, dynamic>? info;

      while (parser.hasMore) {
        final tag = parser.readTag();
        if (tag == null) break;
        final (fieldNumber, wireType) = tag;

        switch (fieldNumber) {
          case 1: // info
            final infoBytes = parser.readLengthDelimited();
            if (infoBytes != null) {
              info = _parseInfo(infoBytes);
              result['info'] = info;
            }
            break;
          case 2: // data
            final dataBytes = parser.readLengthDelimited();
            if (dataBytes != null) {
              result['data'] = _parsePushMessageData(dataBytes);
            }
            break;
          default:
            parser.skipField(wireType);
        }
      }

      if (info != null) {
        result['cmd'] = info['cmd'];
        result['seq'] = info['seq'];
      }

      return result.isNotEmpty ? result : null;
    } catch (e, s) {
      print('解析push_message失败: $e\n$s');
      return null;
    }
  }

  /// 解析INFO
  static Map<String, dynamic> _parseInfo(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;
      final (fieldNumber, wireType) = tag;
      switch (fieldNumber) {
        case 1:
          result['seq'] = parser.readString();
          break;
        case 2:
          result['cmd'] = parser.readString();
          break;
        default:
          parser.skipField(wireType);
      }
    }
    return result;
  }

  /// 解析push_message的Data
  static Map<String, dynamic> _parsePushMessageData(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;
      final (fieldNumber, wireType) = tag;
      switch (fieldNumber) {
        case 1:
          result['any'] = parser.readString();
          break;
        case 2:
          final msgBytes = parser.readLengthDelimited();
          if (msgBytes != null) result['msg'] = _parseWsMsg(msgBytes);
          break;
        default:
          parser.skipField(wireType);
      }
    }
    return result;
  }

  /// 解析WebSocket的Msg消息
  static Map<String, dynamic> _parseWsMsg(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;
      final (fieldNumber, wireType) = tag;
      switch (fieldNumber) {
        case 1:
          result['msg_id'] = parser.readString();
          break;
        case 2:
          final senderBytes = parser.readLengthDelimited();
          if (senderBytes != null) result['sender'] = _parseWsSender(senderBytes);
          break;
        case 3:
          result['recv_id'] = parser.readString();
          break;
        case 4:
          result['chat_id'] = parser.readString();
          break;
        case 5:
          result['chat_type'] = parser.readVarint()?.toInt();
          break;
        case 6:
          final contentBytes = parser.readLengthDelimited();
          if (contentBytes != null) result['content'] = _parseWsContent(contentBytes);
          break;
        case 7:
          result['content_type'] = parser.readVarint()?.toInt();
          break;
        case 8:
          result['timestamp'] = parser.readVarint()?.toInt();
          break;
        case 9:
          final cmdBytes = parser.readLengthDelimited();
          if (cmdBytes != null) result['cmd'] = _parseWsCmd(cmdBytes);
          break;
        case 10:
          result['delete_time'] = parser.readVarint()?.toInt();
          break;
        case 11:
          result['quote_msg_id'] = parser.readString();
          break;
        case 12:
          result['msg_seq'] = parser.readVarint()?.toInt();
          break;
        case 14:
          result['edit_time'] = parser.readVarint()?.toInt();
          break;
        default:
          parser.skipField(wireType);
      }
    }
    return result;
  }

  /// 解析WebSocket的Sender
  static Map<String, dynamic> _parseWsSender(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;
      final (fieldNumber, wireType) = tag;
      switch (fieldNumber) {
        case 1:
          result['chat_id'] = parser.readString();
          break;
        case 2:
          result['chat_type'] = parser.readVarint()?.toInt();
          break;
        case 3:
          result['name'] = parser.readString();
          break;
        case 4:
          result['avatar_url'] = parser.readString();
          break;
        case 6:
          final tagOld = parser.readString();
          if (tagOld != null) {
            (result['tag_old'] ??= <String>[]).add(tagOld);
          }
          break;
        case 7:
          final tagBytes = parser.readLengthDelimited();
          if (tagBytes != null) (result['tag'] ??= <Map<String, dynamic>>[]).add(_parseWsTag(tagBytes));
          break;
        default:
          parser.skipField(wireType);
      }
    }
    return result;
  }

  /// 解析WebSocket的Tag
  static Map<String, dynamic> _parseWsTag(Uint8List data) {
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
        case 3: // text
          result['text'] = parser.readString();
          break;
        case 4: // color
          result['color'] = parser.readString();
          break;
        default:
          parser.skipField(wireType);
      }
    }

    return result;
  }
  static Map<String, dynamic> _parseWsContent(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;
      final (fieldNumber, wireType) = tag;
      switch (fieldNumber) {
        case 1:
          result['text'] = parser.readString();
          break;
        case 2:
          result['buttons'] = parser.readString();
          break;
        case 3:
          result['image_url'] = parser.readString();
          break;
        case 4:
          result['file_name'] = parser.readString();
          break;
        case 5:
          result['file_url'] = parser.readString();
          break;
        case 7:
          result['form'] = parser.readString();
          break;
        case 8:
          result['quote_msg_text'] = parser.readString();
          break;
        case 9:
          result['sticker_url'] = parser.readString();
          break;
        case 10:
          result['post_id'] = parser.readString();
          break;
        case 11:
          result['post_title'] = parser.readString();
          break;
        case 12:
          result['post_content'] = parser.readString();
          break;
        case 13:
          result['post_content_type'] = parser.readString();
          break;
        case 15:
          result['expression_id'] = parser.readString();
          break;
        case 16:
          result['quote_image_url'] = parser.readString();
          break;
        case 17:
          result['quote_image_name'] = parser.readString();
          break;
        case 18:
          result['file_size'] = parser.readVarint()?.toInt();
          break;
        case 19:
          result['video_url'] = parser.readString();
          break;
        case 21:
          result['audio_url'] = parser.readString();
          break;
        case 22:
          result['audio_time'] = parser.readVarint()?.toInt();
          break;
        case 23:
          result['quote_video_url'] = parser.readString();
          break;
        case 24:
          result['quote_video_time'] = parser.readVarint()?.toInt();
          break;
        case 25:
          result['sticker_item_id'] = parser.readVarint()?.toInt();
          break;
        case 26:
          result['sticker_pack_id'] = parser.readVarint()?.toInt();
          break;
        case 29:
          result['call_text'] = parser.readString();
          break;
        case 32:
          result['call_status_text'] = parser.readString();
          break;
        case 33:
          result['width'] = parser.readVarint()?.toInt();
          break;
        case 34:
          result['height'] = parser.readVarint()?.toInt();
          break;
        case 37:
          result['tip'] = parser.readString();
          break;
        default:
          parser.skipField(wireType);
      }
    }
    return result;
  }

  /// 解析WebSocket的Cmd
  static Map<String, dynamic> _parseWsCmd(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;
      final (fieldNumber, wireType) = tag;
      switch (fieldNumber) {
        case 1:
          result['id'] = parser.readVarint()?.toInt();
          break;
        case 2:
          result['name'] = parser.readString();
          break;
        default:
          parser.skipField(wireType);
      }
    }
    return result;
  }

  /// 解析heartbeat_ack
  static Map<String, dynamic>? parseHeartbeatAck(Uint8List data) {
    try {
      final parser = ProtobufParser(data);
      Map<String, dynamic>? info;
      while (parser.hasMore) {
        final tag = parser.readTag();
        if (tag == null) break;
        final (fieldNumber, wireType) = tag;
        if (fieldNumber == 1) {
          final infoBytes = parser.readLengthDelimited();
          if (infoBytes != null) info = _parseInfo(infoBytes);
        } else {
          parser.skipField(wireType);
        }
      }
      return info != null ? {'info': info, 'cmd': info['cmd']} : null;
    } catch (e, s) {
      print('解析heartbeat_ack失败: $e\n$s');
      return null;
    }
  }

  /// 解析draft_input（草稿同步）
  static Map<String, dynamic>? parseDraftInput(Uint8List data) {
    try {
      final parser = ProtobufParser(data);
      final result = <String, dynamic>{};
      Map<String, dynamic>? info;
      while (parser.hasMore) {
        final tag = parser.readTag();
        if (tag == null) break;
        final (fieldNumber, wireType) = tag;
        switch (fieldNumber) {
          case 1:
            final infoBytes = parser.readLengthDelimited();
            if (infoBytes != null) {
              info = _parseInfo(infoBytes);
              result['info'] = info;
            }
            break;
          case 2:
            final dataBytes = parser.readLengthDelimited();
            if (dataBytes != null) result['data'] = _parseDraftInputData(dataBytes);
            break;
          default:
            parser.skipField(wireType);
        }
      }
      if (info != null) result['cmd'] = info['cmd'];
      return result.isNotEmpty ? result : null;
    } catch (e, s) {
      print('解析draft_input失败: $e\n$s');
      return null;
    }
  }

  /// 解析draft_input的Data
  static Map<String, dynamic> _parseDraftInputData(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};
    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;
      final (fieldNumber, wireType) = tag;
      switch (fieldNumber) {
        case 1:
          result['any'] = parser.readString();
          break;
        case 2:
          final draftBytes = parser.readLengthDelimited();
          if (draftBytes != null) result['draft'] = _parseDraft(draftBytes);
          break;
        default:
          parser.skipField(wireType);
      }
    }
    return result;
  }

  /// 解析Draft
  static Map<String, dynamic> _parseDraft(Uint8List data) {
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
        case 2: // input
          result['input'] = parser.readString() ?? '';
          break;
        default:
          parser.skipField(wireType);
      }
    }

    return result;
  }
}

