import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/worker_profile.dart'; // For IdMapping

/// Reactive singleton session store for in-app chat conversations in HomeEase.
///
/// Adheres to PROJECT.md § Milestone 1 & Feature 2 (R2):
/// - Singleton with in-memory session persistence across modal sheet dismissals.
/// - Deterministic conversation ID mapping supporting UUIDs, legacy worker IDs, and name slugs.
/// - Triple reactivity: `ChangeNotifier` updates, broadcast `Stream`, and per-conversation `ValueNotifier`.
/// - Automated worker acknowledgement simulation.
/// - Zero external dependencies, pure Flutter foundation.
class ChatRepository extends ChangeNotifier {
  static final ChatRepository _instance = ChatRepository._internal();
  factory ChatRepository() => _instance;
  static ChatRepository get instance => _instance;

  static int _msgCounter = 0;

  ChatRepository._internal();

  final Map<String, List<ChatMessage>> _conversations = {};
  final Map<String, StreamController<List<ChatMessage>>> _streamControllers = {};
  final Map<String, ValueNotifier<List<ChatMessage>>> _notifiers = {};
  final List<Timer> _pendingTimers = [];

  /// Deterministically derives a conversationId from conversationId, recipientId, or recipientName.
  static String buildConversationId({
    String? conversationId,
    String? recipientId,
    String? recipientName,
  }) {
    if (conversationId != null && conversationId.trim().isNotEmpty) {
      return conversationId.trim();
    }
    if (recipientId != null && recipientId.trim().isNotEmpty) {
      final normalized = IdMapping.toWorkerUuid(recipientId.trim());
      return 'conv_$normalized';
    }
    if (recipientName != null && recipientName.trim().isNotEmpty) {
      final slug = recipientName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      return 'conv_$slug';
    }
    return 'conv_default';
  }

  /// Returns unmodifiable list of messages for a conversation.
  List<ChatMessage> getMessages(String conversationId) {
    return List.unmodifiable(_conversations[conversationId] ?? const []);
  }

  /// Checks if conversation exists and has messages.
  bool hasConversation(String conversationId) {
    return _conversations.containsKey(conversationId) &&
        _conversations[conversationId]!.isNotEmpty;
  }

  /// Initializes a conversation with greeting messages if it does not already exist.
  /// If the conversation already contains messages, it preserves them across sheet dismissals.
  void initConversation({
    required String conversationId,
    String? recipientName,
    String? recipientRole,
    String? serviceContext,
    bool isUrdu = false,
  }) {
    if (_conversations.containsKey(conversationId) &&
        _conversations[conversationId]!.isNotEmpty) {
      // Retain existing messages across sheet dismissals
      return;
    }

    final initial = <ChatMessage>[
      ChatMessage(
        id: 'msg_greet_${DateTime.now().microsecondsSinceEpoch}_1',
        conversationId: conversationId,
        text: isUrdu
            ? 'السلام علیکم! ہوم ایز منتخب کرنے کا شکریہ۔ میں تصدیق شدہ ہوں اور آپ کی مدد کے لیے تیار ہوں۔'
            : 'Assalam-o-Alaikum! Thank you for choosing HomeEase. I am verified and ready to assist you.',
        isMe: false,
        time: '10:15 AM',
      ),
      if (serviceContext != null && serviceContext.isNotEmpty)
        ChatMessage(
          id: 'msg_greet_${DateTime.now().microsecondsSinceEpoch}_2',
          conversationId: conversationId,
          text: isUrdu
              ? '$serviceContext کے حوالے سے: میں تمام ضروری گھریلو اوزار ساتھ لاؤں گا۔'
              : 'Regarding $serviceContext: I will bring all necessary domestic tools with me.',
          isMe: false,
          time: '10:16 AM',
        ),
    ];

    _conversations[conversationId] = initial;
    _notify(conversationId);
  }

  /// Sends a message and optionally schedules an automated acknowledgement.
  ChatMessage sendMessage({
    required String conversationId,
    required String text,
    bool isMe = true,
    String? senderId,
    String? senderName,
    bool autoReply = false,
    bool isUrdu = false,
  }) {
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}_${_msgCounter++}',
      conversationId: conversationId,
      text: text.trim(),
      isMe: isMe,
      senderId: senderId ?? (isMe ? 'user_me' : 'recipient'),
      senderName: senderName ?? (isMe ? 'Me' : 'Worker'),
      timestamp: DateTime.now(),
    );

    _conversations.putIfAbsent(conversationId, () => []).add(msg);
    _notify(conversationId);

    if (autoReply && isMe) {
      late final Timer timer;
      timer = Timer(const Duration(milliseconds: 1200), () {
        _pendingTimers.remove(timer);
        final replyText = isUrdu
            ? 'سمجھ گیا! میں نے آپ کا پیغام نوٹ کر لیا ہے اور شیڈول کے مطابق پہنچوں گا۔'
            : 'Understood! I have noted your message and will adhere to your schedule.';
        final reply = ChatMessage(
          id: 'msg_reply_${DateTime.now().microsecondsSinceEpoch}_${_msgCounter++}',
          conversationId: conversationId,
          text: replyText,
          isMe: false,
          senderId: 'recipient',
          senderName: senderName ?? 'Worker',
          timestamp: DateTime.now(),
        );
        _conversations.putIfAbsent(conversationId, () => []).add(reply);
        _notify(conversationId);
      });
      _pendingTimers.add(timer);
    }

    return msg;
  }

  /// Broadcast stream for a specific conversation.
  /// Automatically emits the current list of messages upon subscription.
  Stream<List<ChatMessage>> watchConversation(String conversationId) {
    final controller = _streamControllers.putIfAbsent(
      conversationId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    Timer.run(() {
      if (!controller.isClosed) {
        controller.add(getMessages(conversationId));
      }
    });
    return controller.stream;
  }

  /// ValueNotifier for fine-grained per-conversation reactive binding.
  ValueNotifier<List<ChatMessage>> getConversationNotifier(String conversationId) {
    return _notifiers.putIfAbsent(
      conversationId,
      () => ValueNotifier<List<ChatMessage>>(getMessages(conversationId)),
    );
  }

  void _notify(String conversationId) {
    final current = getMessages(conversationId);
    if (_notifiers.containsKey(conversationId)) {
      _notifiers[conversationId]!.value = current;
    }
    if (_streamControllers.containsKey(conversationId) &&
        !_streamControllers[conversationId]!.isClosed) {
      _streamControllers[conversationId]!.add(current);
    }
    notifyListeners();
  }

  /// Reset repository state (for unit testing isolation).
  @visibleForTesting
  void reset() {
    for (final t in _pendingTimers) {
      t.cancel();
    }
    _pendingTimers.clear();
    _conversations.clear();
    for (final notifier in _notifiers.values) {
      notifier.value = const [];
    }
    for (final controller in _streamControllers.values) {
      if (!controller.isClosed) {
        controller.add(const []);
      }
    }
    notifyListeners();
  }

  @visibleForTesting
  static void resetInstance() {
    _instance.reset();
  }
}
