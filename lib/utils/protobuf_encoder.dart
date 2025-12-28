import 'dart:convert';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';

/// Protobuf 编码器
/// 手动实现 Protobuf Wire Format 编码
class ProtobufEncoder {
  final List<int> _buffer = [];

  /// 写入 varint
  void writeVarint(Int64 value) {
    var v = value.toInt();
    while (v >= 0x80) {
      _buffer.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    _buffer.add(v & 0x7F);
  }

  /// 写入字段标签和值
  void writeTag(int fieldNumber, int wireType) {
    writeVarint(Int64((fieldNumber << 3) | wireType));
  }

  /// 写入字符串
  void writeString(int fieldNumber, String value) {
    writeTag(fieldNumber, 2); // length-delimited
    final bytes = utf8.encode(value);
    writeVarint(Int64(bytes.length));
    _buffer.addAll(bytes);
  }

  /// 写入 int64
  void writeInt64(int fieldNumber, Int64 value) {
    writeTag(fieldNumber, 0); // varint
    writeVarint(value);
  }

  /// 写入 int32
  void writeInt32(int fieldNumber, int value) {
    writeTag(fieldNumber, 0); // varint
    writeVarint(Int64(value));
  }

  /// 写入 double
  void writeDouble(int fieldNumber, double value) {
    writeTag(fieldNumber, 1); // fixed64
    final buffer = ByteData(8);
    buffer.setFloat64(0, value, Endian.little);
    _buffer.addAll(buffer.buffer.asUint8List());
  }

  /// 写入嵌套消息
  void writeMessage(int fieldNumber, Uint8List message) {
    writeTag(fieldNumber, 2); // length-delimited
    writeVarint(Int64(message.length));
    _buffer.addAll(message);
  }

  /// 写入重复字符串
  void writeRepeatedString(int fieldNumber, List<String> values) {
    for (final value in values) {
      writeString(fieldNumber, value);
    }
  }

  /// 获取编码结果
  Uint8List toBytes() {
    return Uint8List.fromList(_buffer);
  }

  /// 重置编码器
  void reset() {
    _buffer.clear();
  }
}

/// 编码发送消息请求
/// 根据 msg.proto 的 send_message_send 结构
Uint8List encodeSendMessage({
  required String msgId,
  required String chatId,
  required int chatType,
  required String text,
  int contentType = 1,
  String? quoteMsgId,
  int? commandId,
}) {
  try {
    print('========== 编码发送消息 ==========');
    print('输入参数: msgId=$msgId, chatId=$chatId, chatType=$chatType, text=$text, contentType=$contentType');
    
    final encoder = ProtobufEncoder();
    print('创建 encoder 完成');
    
    // 编码 Content (send_message_send.Content)
    print('开始编码 Content...');
    final contentEncoder = ProtobufEncoder();
    print('创建 contentEncoder 完成');
    
    print('准备写入 text (field 1): "$text"');
    contentEncoder.writeString(1, text); // text
    print('写入 text 完成');
    
    final contentBytes = contentEncoder.toBytes();
    print('Content 编码完成，长度: ${contentBytes.length} 字节');
    if (contentBytes.isNotEmpty) {
      print('Content 前20字节: ${contentBytes.take(20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    }
    
    // 编码 send_message_send
    print('开始编码 send_message_send...');
    print('准备写入 msg_id (field 2): "$msgId"');
    encoder.writeString(2, msgId); // msg_id
    print('写入 msg_id 完成');
    
    print('准备写入 chat_id (field 3): "$chatId"');
    encoder.writeString(3, chatId); // chat_id
    print('写入 chat_id 完成');
    
    print('准备写入 chat_type (field 4): $chatType');
    encoder.writeInt64(4, Int64(chatType)); // chat_type
    print('写入 chat_type 完成');
    
    print('准备写入 content (field 5)，长度: ${contentBytes.length}');
    encoder.writeMessage(5, contentBytes); // Content
    print('写入 content 完成');
    
    print('准备写入 content_type (field 6): $contentType');
    encoder.writeInt64(6, Int64(contentType)); // content_type
    print('写入 content_type 完成');
    
    if (commandId != null) {
      print('准备写入 command_id (field 7): $commandId');
      encoder.writeInt64(7, Int64(commandId)); // command_id
      print('写入 command_id 完成');
    }
    
    if (quoteMsgId != null) {
      print('准备写入 quote_msg_id (field 8): "$quoteMsgId"');
      encoder.writeString(8, quoteMsgId); // quote_msg_id
      print('写入 quote_msg_id 完成');
    }
    
    print('准备获取编码结果...');
    final result = encoder.toBytes();
    print('编码完成，总长度: ${result.length} 字节');
    if (result.isNotEmpty) {
      print('编码结果前50字节: ${result.take(50).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    }
    print('========== 编码发送消息结束 ==========');
    
    return result;
  } catch (e, stackTrace) {
    print('========== 编码发送消息异常 ==========');
    print('异常类型: ${e.runtimeType}');
    print('异常信息: $e');
    print('堆栈跟踪:');
    print(stackTrace);
    print('========== 编码发送消息异常结束 ==========');
    rethrow;
  }
}

/// 编码获取消息列表请求
Uint8List encodeListMessage({
  required String chatId,
  required int chatType,
  required int msgCount,
  String? msgId,
}) {
  final encoder = ProtobufEncoder();
  
  encoder.writeInt64(2, Int64(msgCount)); // msg_count
  if (msgId != null) {
    encoder.writeString(3, msgId); // msg_id
  }
  encoder.writeInt64(4, Int64(chatType)); // chat_type
  encoder.writeString(5, chatId); // chat_id
  
  return encoder.toBytes();
}

/// 编码获取用户信息请求
Uint8List encodeGetUser({required String userId}) {
  final encoder = ProtobufEncoder();
  encoder.writeString(2, userId); // id
  return encoder.toBytes();
}

/// 编码获取通讯录列表请求
Uint8List encodeAddressBookListSend({required String number}) {
  final encoder = ProtobufEncoder();
  encoder.writeString(2, number); // number
  return encoder.toBytes();
}

/// 编码获取群聊信息请求
/// 根据 group.proto 的 info_send 结构
Uint8List encodeGroupInfoSend({required String groupId}) {
  final encoder = ProtobufEncoder();
  encoder.writeString(2, groupId); // group_id
  return encoder.toBytes();
}

