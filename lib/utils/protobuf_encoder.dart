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
  final encoder = ProtobufEncoder();
  
  // 编码 Content (send_message_send.Content)
  final contentEncoder = ProtobufEncoder();
  contentEncoder.writeString(1, text); // text
  final contentBytes = contentEncoder.toBytes();
  
  // 编码 send_message_send
  encoder.writeString(2, msgId); // msg_id
  encoder.writeString(3, chatId); // chat_id
  encoder.writeInt64(4, Int64(chatType)); // chat_type
  encoder.writeMessage(5, contentBytes); // Content (data字段在proto中实际是Content)
  encoder.writeInt64(6, Int64(contentType)); // content_type
  if (commandId != null) {
    encoder.writeInt64(7, Int64(commandId)); // command_id
  }
  if (quoteMsgId != null) {
    encoder.writeString(8, quoteMsgId); // quote_msg_id
  }
  
  return encoder.toBytes();
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

