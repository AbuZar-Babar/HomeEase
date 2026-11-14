class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'Payment', 'Booking', 'Dispute', 'Verification', 'System'
  final bool isRead;
  final DateTime createdAt;
  final String? titleUrdu;
  final String? messageUrdu;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.titleUrdu,
    this.messageUrdu,
    this.metadata,
  });

  String localizedTitle(bool isUrdu) {
    if (isUrdu && titleUrdu != null && titleUrdu!.isNotEmpty) {
      return titleUrdu!;
    }
    return title;
  }

  String localizedMessage(bool isUrdu) {
    if (isUrdu && messageUrdu != null && messageUrdu!.isNotEmpty) {
      return messageUrdu!;
    }
    return message;
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? titleUrdu,
    String? messageUrdu,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      titleUrdu: titleUrdu ?? this.titleUrdu,
      messageUrdu: messageUrdu ?? this.messageUrdu,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    final rawDate = map['created_at'] ?? map['createdAt'];
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    return NotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'System',
      isRead: map['is_read'] == true || map['isRead'] == true,
      createdAt: parsedDate,
      titleUrdu: map['title_urdu']?.toString() ?? map['titleUrdu']?.toString(),
      messageUrdu: map['message_urdu']?.toString() ?? map['messageUrdu']?.toString(),
      metadata: map['metadata'] is Map<String, dynamic> ? map['metadata'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      if (titleUrdu != null) 'title_urdu': titleUrdu,
      if (messageUrdu != null) 'message_urdu': messageUrdu,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
