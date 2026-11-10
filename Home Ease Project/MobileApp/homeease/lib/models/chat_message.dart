import 'package:flutter/foundation.dart';

/// Immutable model representing an individual chat message in HomeEase direct messaging.
@immutable
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String time;
  final bool isRead;
  final String? attachmentUrl;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.isMe,
    DateTime? timestamp,
    String? time,
    this.senderId = '',
    this.senderName = '',
    this.isRead = true,
    this.attachmentUrl,
  })  : timestamp = timestamp ?? DateTime.now(),
        time = time ?? _formatTime(timestamp ?? DateTime.now());

  static String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'sender_name': senderName,
    'text': text,
    'is_me': isMe,
    'timestamp': timestamp.toIso8601String(),
    'time': time,
    'is_read': isRead,
    if (attachmentUrl != null) 'attachment_url': attachmentUrl,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    DateTime? parsedTimestamp;
    if (rawTimestamp is DateTime) {
      parsedTimestamp = rawTimestamp;
    } else if (rawTimestamp is String && rawTimestamp.isNotEmpty) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp);
    }

    return ChatMessage(
      id: map['id']?.toString() ?? '',
      conversationId: map['conversation_id']?.toString() ??
          map['conversationId']?.toString() ??
          '',
      senderId: map['sender_id']?.toString() ??
          map['senderId']?.toString() ??
          '',
      senderName: map['sender_name']?.toString() ??
          map['senderName']?.toString() ??
          '',
      text: map['text']?.toString() ?? '',
      isMe: map['is_me'] as bool? ??
          map['isMe'] as bool? ??
          false,
      timestamp: parsedTimestamp,
      time: map['time']?.toString(),
      isRead: map['is_read'] as bool? ??
          map['isRead'] as bool? ??
          true,
      attachmentUrl: map['attachment_url']?.toString() ??
          map['attachmentUrl']?.toString(),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? text,
    bool? isMe,
    DateTime? timestamp,
    String? time,
    bool? isRead,
    String? attachmentUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          text == other.text &&
          isMe == other.isMe;

  @override
  int get hashCode => Object.hash(id, conversationId, text, isMe);

  @override
  String toString() =>
      'ChatMessage(id: $id, conv: $conversationId, isMe: $isMe, text: $text, time: $time)';
}
