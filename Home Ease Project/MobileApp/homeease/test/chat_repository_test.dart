import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/models/chat_message.dart';
import 'package:homeease/services/chat_repository.dart';
import 'package:homeease/services/localization_service.dart';

void main() {
  setUp(() {
    ChatRepository.resetInstance();
    LocalizationService.setLanguage('en');
  });

  tearDown(() {
    ChatRepository.resetInstance();
  });

  group('ChatMessage Model - Serialization & Integrity', () {
    test('CHAT-MOD-01: ChatMessage serialization toMap and fromMap preserves fields', () {
      final now = DateTime(2026, 10, 18, 14, 30);
      final msg = ChatMessage(
        id: 'msg_test_01',
        conversationId: 'conv_123',
        senderId: 'user_01',
        senderName: 'Test Employer',
        text: 'Hello, can you start at 10 AM?',
        isMe: true,
        timestamp: now,
        time: '2:30 PM',
        isRead: false,
        attachmentUrl: 'https://example.com/receipt.jpg',
      );

      final map = msg.toMap();
      expect(map['id'], 'msg_test_01');
      expect(map['conversation_id'], 'conv_123');
      expect(map['sender_id'], 'user_01');
      expect(map['sender_name'], 'Test Employer');
      expect(map['text'], 'Hello, can you start at 10 AM?');
      expect(map['is_me'], isTrue);
      expect(map['is_read'], isFalse);
      expect(map['attachment_url'], 'https://example.com/receipt.jpg');

      final deserialized = ChatMessage.fromMap(map);
      expect(deserialized.id, msg.id);
      expect(deserialized.conversationId, msg.conversationId);
      expect(deserialized.senderId, msg.senderId);
      expect(deserialized.senderName, msg.senderName);
      expect(deserialized.text, msg.text);
      expect(deserialized.isMe, msg.isMe);
      expect(deserialized.isRead, msg.isRead);
      expect(deserialized.attachmentUrl, msg.attachmentUrl);
    });

    test('CHAT-MOD-02: copyWith creates modified instance while keeping unmodified fields', () {
      final msg = ChatMessage(
        id: 'msg_orig',
        conversationId: 'conv_orig',
        text: 'Initial text',
        isMe: true,
      );

      final updated = msg.copyWith(text: 'Updated text', isRead: false);
      expect(updated.id, 'msg_orig');
      expect(updated.conversationId, 'conv_orig');
      expect(updated.text, 'Updated text');
      expect(updated.isRead, isFalse);
      expect(updated.isMe, isTrue);
    });

    test('CHAT-MOD-03: Equality and hashCode compare by value', () {
      final msg1 = ChatMessage(
        id: 'msg_same',
        conversationId: 'conv_1',
        text: 'Same content',
        isMe: true,
      );
      final msg2 = ChatMessage(
        id: 'msg_same',
        conversationId: 'conv_1',
        text: 'Same content',
        isMe: true,
      );
      final msg3 = ChatMessage(
        id: 'msg_diff',
        conversationId: 'conv_1',
        text: 'Different',
        isMe: false,
      );

      expect(msg1, equals(msg2));
      expect(msg1.hashCode, equals(msg2.hashCode));
      expect(msg1 == msg3, isFalse);
    });
  });

  group('ChatRepository - Singleton & Lifecycle', () {
    test('CHAT-REPO-01: ChatRepository is a singleton instance', () {
      final repo1 = ChatRepository();
      final repo2 = ChatRepository();
      expect(identical(repo1, repo2), isTrue);
      expect(identical(repo1, ChatRepository.instance), isTrue);
    });

    test('CHAT-REPO-02: resetInstance clears conversations and notifiers', () {
      final repo = ChatRepository.instance;
      repo.sendMessage(conversationId: 'test_conv', text: 'Hello');
      expect(repo.getMessages('test_conv'), isNotEmpty);

      ChatRepository.resetInstance();
      expect(repo.getMessages('test_conv'), isEmpty);
      expect(repo.hasConversation('test_conv'), isFalse);
    });
  });

  group('ChatRepository - Conversation ID Resolution', () {
    test('CHAT-REPO-03: Maps explicit conversationId directly', () {
      final id = ChatRepository.buildConversationId(conversationId: 'custom_123');
      expect(id, 'custom_123');
    });

    test('CHAT-REPO-04: Normalizes legacy workerId to canonical UUID conversationId', () {
      final id = ChatRepository.buildConversationId(recipientId: 'worker_1');
      expect(id, 'conv_00000000-0000-0000-0000-000000000010');
    });

    test('CHAT-REPO-05: Sanitizes recipientName into slug when recipientId is omitted', () {
      final id = ChatRepository.buildConversationId(recipientName: 'Rabia Bibi');
      expect(id, 'conv_rabia_bibi');
    });

    test('CHAT-REPO-06: Falls back to default key when all arguments are null/empty', () {
      final id = ChatRepository.buildConversationId();
      expect(id, 'conv_default');
    });
  });

  group('ChatRepository - Session Persistence Across Invocations', () {
    test('CHAT-REPO-07: initConversation initializes greeting messages on first invocation', () {
      final repo = ChatRepository.instance;
      repo.initConversation(
        conversationId: 'conv_rabia',
        recipientName: 'Rabia Bibi',
        serviceContext: 'Cook Booking',
        isUrdu: false,
      );

      final messages = repo.getMessages('conv_rabia');
      expect(messages.length, 2);
      expect(messages.first.text, contains('Assalam-o-Alaikum!'));
      expect(messages.last.text, contains('Regarding Cook Booking:'));
    });

    test('CHAT-REPO-08: initConversation in Urdu uses Urdu greetings', () {
      final repo = ChatRepository.instance;
      repo.initConversation(
        conversationId: 'conv_urdu',
        recipientName: 'Rabia Bibi',
        serviceContext: 'کھانا پکانا',
        isUrdu: true,
      );

      final messages = repo.getMessages('conv_urdu');
      expect(messages.length, 2);
      expect(messages.first.text, contains('السلام علیکم!'));
      expect(messages.last.text, contains('کھانا پکانا کے حوالے سے:'));
    });

    test('CHAT-REPO-09: Subsequent initConversation retains existing user messages (Session Persistence)', () {
      final repo = ChatRepository.instance;
      const convId = 'conv_session_test';

      // 1. Initial open
      repo.initConversation(conversationId: convId, recipientName: 'Rabia Bibi');
      expect(repo.getMessages(convId).length, 1);

      // 2. User sends negotiation messages
      repo.sendMessage(
        conversationId: convId,
        text: 'Can you bring your own spices?',
        isMe: true,
      );
      repo.sendMessage(
        conversationId: convId,
        text: 'Also please arrive at 11 AM.',
        isMe: true,
      );
      expect(repo.getMessages(convId).length, 3);

      // 3. User closes modal sheet, then reopens it (triggering initConversation again)
      repo.initConversation(conversationId: convId, recipientName: 'Rabia Bibi');

      // 4. Must NOT overwrite or discard prior messages
      final retained = repo.getMessages(convId);
      expect(retained.length, 3);
      expect(retained[1].text, 'Can you bring your own spices?');
      expect(retained[2].text, 'Also please arrive at 11 AM.');
    });
  });

  group('ChatRepository - Reactive Subscriptions & Streams', () {
    test('CHAT-REPO-10: sendMessage triggers ChangeNotifier listeners', () {
      final repo = ChatRepository.instance;
      int notifyCount = 0;
      void listener() => notifyCount++;

      repo.addListener(listener);
      repo.sendMessage(conversationId: 'conv_listen', text: 'Ping');
      repo.sendMessage(conversationId: 'conv_listen', text: 'Pong');

      expect(notifyCount, 2);
      repo.removeListener(listener);
    });

    test('CHAT-REPO-11: ValueNotifier reflects updated conversation messages', () {
      final repo = ChatRepository.instance;
      final notifier = repo.getConversationNotifier('conv_notifier');

      expect(notifier.value, isEmpty);

      repo.sendMessage(conversationId: 'conv_notifier', text: 'First message');
      expect(notifier.value.length, 1);
      expect(notifier.value.first.text, 'First message');

      repo.sendMessage(conversationId: 'conv_notifier', text: 'Second message');
      expect(notifier.value.length, 2);
      expect(notifier.value.last.text, 'Second message');
    });

    test('CHAT-REPO-12: watchConversation broadcast stream emits current and new messages', () async {
      final repo = ChatRepository.instance;
      const convId = 'conv_stream';

      repo.sendMessage(conversationId: convId, text: 'Pre-existing message');

      final stream = repo.watchConversation(convId);
      final receivedLists = <List<ChatMessage>>[];

      final sub = stream.listen((list) {
        receivedLists.add(list);
      });

      // Allow microtask to emit initial messages
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repo.sendMessage(conversationId: convId, text: 'Live message');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(receivedLists.isNotEmpty, isTrue);
      expect(receivedLists.last.length, 2);
      expect(receivedLists.last.last.text, 'Live message');

      await sub.cancel();
    });

    test('CHAT-REPO-13: autoReply schedules simulated worker acknowledgment', () async {
      final repo = ChatRepository.instance;
      const convId = 'conv_autoreply';

      repo.sendMessage(
        conversationId: convId,
        text: 'What time can you come?',
        isMe: true,
        autoReply: true,
      );

      expect(repo.getMessages(convId).length, 1);

      // Wait for simulated reply (1200ms delay)
      await Future<void>.delayed(const Duration(milliseconds: 1300));

      final after = repo.getMessages(convId);
      expect(after.length, 2);
      expect(after.last.isMe, isFalse);
      expect(after.last.text, contains('Understood!'));
    });
  });
}
