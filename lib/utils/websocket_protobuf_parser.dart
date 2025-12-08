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
      Map<String, dynamic>? msgData;

      while (parser.hasMore) {
        final tag = parser.readTag();
        if (tag == null) break;

        final (fieldNumber, wireType) = tag;

        switch (fieldNumber) {
          case 1: // info
            final infoBytes = parser.readLengthDelimited();
            if (infoBytes != null) {
              info = parseInfo(infoBytes);
              result['info'] = info;
            }
            break;
          case 2: // data
            final dataBytes = parser.readLengthDelimited();
            if (dataBytes != null) {
              msgData = parsePushMessageData(dataBytes);
              result['data'] = msgData;
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

      return result;
    } catch (e) {
      print('解析push_message失败: $e');
      return null;
    }
  }

  /// 解析INFO
  static Map<String, dynamic> parseInfo(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};

    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;

      final (fieldNumber, wireType) = tag;

      switch (fieldNumber) {
        case 1: // seq
          result['seq'] = parser.readString() ?? '';
          break;
        case 2: // cmd
          result['cmd'] = parser.readString() ?? '';
          break;
        default:
          parser.skipField(wireType);
      }
    }

    return result;
  }

  /// 解析push_message的Data
  static Map<String, dynamic> parsePushMessageData(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};

    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;

      final (fieldNumber, wireType) = tag;

      switch (fieldNumber) {
        case 1: // any
          result['any'] = parser.readString();
          break;
        case 2: // msg
          final msgBytes = parser.readLengthDelimited();
          if (msgBytes != null) {
            result['msg'] = parseWsMsg(msgBytes);
          }
          break;
        default:
          parser.skipField(wireType);
      }
    }

    return result;
  }

  /// 解析WebSocket的Msg消息
  static Map<String, dynamic> parseWsMsg(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};

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
            result['sender'] = parseWsSender(senderBytes);
          }
          break;
        case 3: // recv_id
          result['recv_id'] = parser.readString();
          break;
        case 4: // chat_id
          result['chat_id'] = parser.readString() ?? '';
          break;
        case 5: // chat_type
          result['chat_type'] = parser.readVarint()?.toInt() ?? 1;
          break;
        case 6: // content
          final contentBytes = parser.readLengthDelimited();
          if (contentBytes != null) {
            result['content'] = parseWsContent(contentBytes);
          }
          break;
        case 7: // content_type
          result['content_type'] = parser.readVarint()?.toInt() ?? 1;
          break;
        case 8: // timestamp
          result['timestamp'] = parser.readVarint()?.toInt();
          break;
        case 9: // cmd
          final cmdBytes = parser.readLengthDelimited();
          if (cmdBytes != null) {
            result['cmd'] = parseWsCmd(cmdBytes);
          }
          break;
        case 10: // delete_time
          result['delete_time'] = parser.readVarint()?.toInt();
          break;
        case 11: // quote_msg_id
          result['quote_msg_id'] = parser.readString();
          break;
        case 12: // msg_seq
          result['msg_seq'] = parser.readVarint()?.toInt();
          break;
        case 14: // edit_time
          result['edit_time'] = parser.readVarint()?.toInt();
          break;
        default:
          parser.skipField(wireType);
      }
    }

    return result;
  }

  /// 解析WebSocket的Sender
  static Map<String, dynamic> parseWsSender(Uint8List data) {
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
        case 6: // tag_old (repeated)
          final tagOld = parser.readString();
          if (tagOld != null) {
            if (result['tag_old'] == null) {
              result['tag_old'] = <String>[];
            }
            (result['tag_old'] as List<String>).add(tagOld);
          }
          break;
        case 7: // tag (repeated)
          final tagBytes = parser.readLengthDelimited();
          if (tagBytes != null) {
            if (result['tag'] == null) {
              result['tag'] = <Map<String, dynamic>>[];
            }
            (result['tag'] as List<Map<String, dynamic>>).add(parseWsTag(tagBytes));
          }
          break;
        default:
          parser.skipField(wireType);
      }
    }

    return result;
  }

  /// 解析WebSocket的Tag
  static Map<String, dynamic> parseWsTag(Uint8List data) {
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

  /// 解析WebSocket的Content
  static Map<String, dynamic> parseWsContent(Uint8List data) {
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
        case 2: // buttons
          result['buttons'] = parser.readString();
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
        case 7: // form
          result['form'] = parser.readString();
          break;
        case 8: // quote_msg_text
          result['quote_msg_text'] = parser.readString();
          break;
        case 9: // sticker_url
          result['sticker_url'] = parser.readString();
          break;
        case 10: // post_id
          result['post_id'] = parser.readString();
          break;
        case 11: // post_title
          result['post_title'] = parser.readString();
          break;
        case 12: // post_content
          result['post_content'] = parser.readString();
          break;
        case 13: // post_content_type
          result['post_content_type'] = parser.readString();
          break;
        case 15: // expression_id
          result['expression_id'] = parser.readString();
          break;
        case 16: // quote_image_url
          result['quote_image_url'] = parser.readString();
          break;
        case 17: // quote_image_name
          result['quote_image_name'] = parser.readString();
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
        case 23: // quote_video_url
          result['quote_video_url'] = parser.readString();
          break;
        case 24: // quote_video_time
          result['quote_video_time'] = parser.readVarint()?.toInt();
          break;
        case 25: // sticker_item_id
          result['sticker_item_id'] = parser.readVarint()?.toInt();
          break;
        case 26: // sticker_pack_id
          result['sticker_pack_id'] = parser.readVarint()?.toInt();
          break;
        case 29: // call_text
          result['call_text'] = parser.readString();
          break;
        case 32: // call_status_text
          result['call_status_text'] = parser.readString();
          break;
        case 33: // width
          result['width'] = parser.readVarint()?.toInt();
          break;
        case 34: // height
          result['height'] = parser.readVarint()?.toInt();
          break;
        case 37: // tip
          result['tip'] = parser.readString();
          break;
        default:
          parser.skipField(wireType);
      }
    }

    return result;
  }

  /// 解析WebSocket的Cmd
  static Map<String, dynamic> parseWsCmd(Uint8List data) {
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

        switch (fieldNumber) {
          case 1: // info
            final infoBytes = parser.readLengthDelimited();
            if (infoBytes != null) {
              info = parseInfo(infoBytes);
            }
            break;
          default:
            parser.skipField(wireType);
        }
      }

      return info != null ? {'info': info, 'cmd': info['cmd']} : null;
    } catch (e) {
      print('解析heartbeat_ack失败: $e');
      return null;
    }
  }

  /// 解析draft_input（草稿同步）
  static Map<String, dynamic>? parseDraftInput(Uint8List data) {
    try {
      final parser = ProtobufParser(data);
      final result = <String, dynamic>{};
      Map<String, dynamic>? info;
      Map<String, dynamic>? draftData;

      while (parser.hasMore) {
        final tag = parser.readTag();
        if (tag == null) break;

        final (fieldNumber, wireType) = tag;

        switch (fieldNumber) {
          case 1: // info
            final infoBytes = parser.readLengthDelimited();
            if (infoBytes != null) {
              info = parseInfo(infoBytes);
              result['info'] = info;
            }
            break;
          case 2: // data
            final dataBytes = parser.readLengthDelimited();
            if (dataBytes != null) {
              draftData = parseDraftInputData(dataBytes);
              result['data'] = draftData;
            }
            break;
          default:
            parser.skipField(wireType);
        }
      }

      if (info != null) {
        result['cmd'] = info['cmd'];
      }

      return result;
    } catch (e) {
      print('解析draft_input失败: $e');
      return null;
    }
  }

  /// 解析draft_input的Data
  static Map<String, dynamic> parseDraftInputData(Uint8List data) {
    final parser = ProtobufParser(data);
    final result = <String, dynamic>{};

    while (parser.hasMore) {
      final tag = parser.readTag();
      if (tag == null) break;

      final (fieldNumber, wireType) = tag;

      switch (fieldNumber) {
        case 1: // any
          result['any'] = parser.readString();
          break;
        case 2: // draft
          final draftBytes = parser.readLengthDelimited();
          if (draftBytes != null) {
            result['draft'] = parseDraft(draftBytes);
          }
          break;
        default:
          parser.skipField(wireType);
      }
    }

    return result;
  }

  /// 解析Draft
  static Map<String, dynamic> parseDraft(Uint8List data) {
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

