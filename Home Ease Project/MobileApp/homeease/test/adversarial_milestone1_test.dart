import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeease/models/chat_message.dart';
import 'package:homeease/models/worker_profile.dart';
import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/services/chat_repository.dart';

void main() {
  setUp(() {
    ChatRepository.resetInstance();
    final bRepo = BookingRepository();
    bRepo.reset();
  });

  tearDown(() {
    ChatRepository.resetInstance();
  });

  group('ADV-CHAT: Concurrency & Stress Harness', () {
    test('ADV-CHAT-01: 100 concurrent asynchronous message sends preserve exact count and integrity', () async {
      final repo = ChatRepository.instance;
      const convId = 'adv_conv_concurrent';

      // Send 100 concurrent messages via Future.wait
      final futures = List.generate(100, (i) async {
        return repo.sendMessage(
          conversationId: convId,
          text: 'Concurrent message #$i',
          isMe: i % 2 == 0,
          senderId: 'user_$i',
        );
      });

      final sentMessages = await Future.wait(futures);
      expect(sentMessages.length, 100);

      final retrieved = repo.getMessages(convId);
      expect(retrieved.length, 100);

      // Verify all unique IDs and texts are present
      final ids = retrieved.map((m) => m.id).toSet();
      expect(ids.length, 100, reason: 'Every message must have a unique ID');

      final texts = retrieved.map((m) => m.text).toSet();
      expect(texts.length, 100, reason: 'All 100 distinct payloads must exist without race drops');
    });

    test('ADV-CHAT-02: Multiple concurrent stream subscribers receive broadcasts synchronously without drop', () async {
      final repo = ChatRepository.instance;
      const convId = 'adv_conv_subscribers';

      repo.sendMessage(conversationId: convId, text: 'Initial message');

      const subscriberCount = 10;
      final receivedCounts = List.filled(subscriberCount, 0);
      final subscriptions = <StreamSubscription<List<ChatMessage>>>[];

      for (int i = 0; i < subscriberCount; i++) {
        final index = i;
        final stream = repo.watchConversation(convId);
        final sub = stream.listen((list) {
          receivedCounts[index] = list.length;
        });
        subscriptions.add(sub);
      }

      // Allow initial Timer.run broadcast
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Emit 5 additional messages
      for (int i = 1; i <= 5; i++) {
        repo.sendMessage(conversationId: convId, text: 'Broadcast stream step $i');
      }

      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Each subscriber must have witnessed the final length (1 initial + 5 new = 6)
      for (int i = 0; i < subscriberCount; i++) {
        expect(receivedCounts[i], 6, reason: 'Subscriber #$i missed messages');
        await subscriptions[i].cancel();
      }
    });

    test('ADV-CHAT-03: Rapid modal sheet reopen simulation retains session and avoids greeting duplication', () {
      final repo = ChatRepository.instance;
      const convId = 'adv_conv_rapid_reopen';

      // Simulate user opening sheet, chatting, dismissing, reopening 25 times
      for (int cycle = 0; cycle < 25; cycle++) {
        repo.initConversation(
          conversationId: convId,
          recipientName: 'Sana Gul',
          serviceContext: 'Deep House Cleaning',
        );

        if (cycle == 0) {
          expect(repo.getMessages(convId).length, 2, reason: 'Should have initial 2 greetings');
        } else {
          // Verify greeting messages did not duplicate
          final greetings = repo.getMessages(convId).where((m) => m.id.startsWith('msg_greet_')).toList();
          expect(greetings.length, 2, reason: 'Greetings must not duplicate on cycle $cycle');
        }

        // Add a message in this session cycle
        repo.sendMessage(
          conversationId: convId,
          text: 'Negotiation note cycle $cycle',
          isMe: true,
        );
      }

      // Expected: 2 initial greetings + 25 messages = 27 total messages
      final finalMessages = repo.getMessages(convId);
      expect(finalMessages.length, 27);
    });

    test('ADV-CHAT-04: Adversarial conversation ID resolution with malformed, whitespace, and special inputs', () {
      // 1. All empty / whitespace falls back to conv_default
      expect(ChatRepository.buildConversationId(), 'conv_default');
      expect(ChatRepository.buildConversationId(conversationId: '', recipientId: '', recipientName: ''), 'conv_default');
      expect(ChatRepository.buildConversationId(conversationId: '   ', recipientId: '   ', recipientName: '   '), 'conv_default');

      // 2. Untrimmed explicit conversationId
      expect(ChatRepository.buildConversationId(conversationId: '  conv_custom_99  '), 'conv_custom_99');

      // 3. Untrimmed legacy workerId mapped to UUID
      expect(
        ChatRepository.buildConversationId(recipientId: '  worker_1  '),
        'conv_00000000-0000-0000-0000-000000000010',
      );

      // 4. Untrimmed canonical UUID recipientId
      expect(
        ChatRepository.buildConversationId(recipientId: ' 00000000-0000-0000-0000-000000000012 '),
        'conv_00000000-0000-0000-0000-000000000012',
      );

      // 5. Urdu recipient name slugification
      final urduSlug = ChatRepository.buildConversationId(recipientName: '  عائشہ   بی بی  \n\t');
      expect(urduSlug, 'conv_عائشہ_بی_بی');

      // 6. Name with punctuation and mixed casing
      final mixedSlug = ChatRepository.buildConversationId(recipientName: '  Dr. Muhammad Ali, PhD  ');
      expect(mixedSlug, 'conv_dr._muhammad_ali,_phd');
    });

    test('ADV-CHAT-05: 100k character text payload and SQL/XSS injection payloads serialize cleanly', () {
      final repo = ChatRepository.instance;
      const convId = 'adv_conv_extreme_payload';

      // 100,000 characters payload
      final hugeText = 'A' * 100000;
      final hugeMsg = repo.sendMessage(
        conversationId: convId,
        text: hugeText,
        isMe: true,
      );
      expect(hugeMsg.text.length, 100000);
      expect(repo.getMessages(convId).first.text.length, 100000);

      // SQL & Script injection strings
      const injectionText = "<script>alert('XSS');</script>'; DROP TABLE bookings; -- \u0000\u202E\u200B";
      final injectMsg = repo.sendMessage(
        conversationId: convId,
        text: injectionText,
        isMe: false,
      );

      final map = injectMsg.toMap();
      final roundTrip = ChatMessage.fromMap(map);
      expect(roundTrip.text, injectionText);
      expect(roundTrip, equals(injectMsg));
    });

    test('ADV-CHAT-06: Test isolation via reset() clears storage and emits empty lists to listeners', () {
      final repo = ChatRepository.instance;
      const convId = 'adv_conv_isolation';

      final notifier = repo.getConversationNotifier(convId);
      repo.sendMessage(conversationId: convId, text: 'Before reset');
      expect(notifier.value.length, 1);
      expect(repo.hasConversation(convId), isTrue);

      // Execute resetInstance
      ChatRepository.resetInstance();

      expect(repo.hasConversation(convId), isFalse);
      expect(repo.getMessages(convId), isEmpty);
      expect(notifier.value, isEmpty, reason: 'ValueNotifier must be notified of empty state on reset');
    });

    test('ADV-CHAT-07: Auto-reply timer behavior across reset()', () async {
      final repo = ChatRepository.instance;
      const convId = 'adv_conv_timer_reset';

      repo.sendMessage(
        conversationId: convId,
        text: 'Hello test',
        autoReply: true,
      );
      expect(repo.getMessages(convId).length, 1);

      // Reset before timer expires (100ms < 1200ms)
      await Future<void>.delayed(const Duration(milliseconds: 100));
      ChatRepository.resetInstance();
      expect(repo.getMessages(convId), isEmpty);

      // Verify that managed timer was cleanly cancelled by reset() and did not resurrect state
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      final messagesAfterTimer = repo.getMessages(convId);
      expect(
        messagesAfterTimer.length,
        0,
        reason: 'Pending auto-reply timer must be cancelled by reset() without resurrecting messages',
      );
    });

    test('ADV-CHAT-08: Burst of 5 autoReply messages generates colliding reply IDs', () async {
      final repo = ChatRepository.instance;
      const convId = 'adv_conv_autoreply_burst';

      for (int i = 0; i < 5; i++) {
        repo.sendMessage(
          conversationId: convId,
          text: 'Burst prompt $i',
          autoReply: true,
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 1350));
      final messages = repo.getMessages(convId);
      expect(messages.length, 10, reason: '5 sent + 5 auto-replies');

      final replyIds = messages.where((m) => m.id.startsWith('msg_reply_')).map((m) => m.id).toSet();
      // If there are collisions among the 5 replies, replyIds.length will be < 5
      expect(replyIds.length, 5, reason: 'Every auto-reply message must have a unique ID');
    });
  });

  group('ADV-BKG: synthesizeConfirmedBooking Conflict & Rate Stress', () {
    test('ADV-BKG-01: Default 9:00 - 12:00 morning slot is assigned when worker is unconflicted', () async {
      final repo = BookingRepository();
      repo.reset();

      final job = JobPost(
        id: '00000000-0000-0000-0000-000000000101',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Babar Khan',
        title: 'Morning Plumbing',
        serviceCategory: 'Plumber',
        description: 'Fix leak',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.19,
        longitude: 73.23,
        budget: 2500.0,
        requiredDate: DateTime(2026, 12, 10),
        status: 'open',
        createdAt: DateTime.now(),
      );

      final app = JobApplication(
        id: 'app_adv_01',
        jobPostId: job.id,
        workerId: '00000000-0000-0000-0000-000000000010', // Rabia Bibi
        workerName: 'Rabia Bibi',
        workerRole: 'Plumber',
        workerRating: 4.8,
        proposedRate: 2300.0,
        notes: 'Can come in morning',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      final booking = await repo.synthesizeConfirmedBooking(job: job, application: app);

      expect(booking.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(booking.endTime, const TimeOfDay(hour: 12, minute: 0));
      expect(booking.agreedAmount, 2300.0);
      expect(booking.status, 'Accepted');
    });

    test('ADV-BKG-02: Morning slot conflict automatically shifts to 14:00 - 17:00 afternoon fallback', () async {
      final repo = BookingRepository();
      repo.reset();

      final targetDate = DateTime(2026, 12, 11);
      const workerId = '00000000-0000-0000-0000-000000000010';

      // 1. Pre-occupy morning slot 10:00 - 11:30 (overlaps with 9:00 - 12:00)
      final existingBooking = Booking(
        id: '00000000-0000-0000-0000-000000000999',
        householdId: '00000000-0000-0000-0000-000000000002',
        workerId: workerId,
        serviceCategoryId: 'Plumber',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 30),
        address: 'Mandian',
        notes: 'Pre-existing morning job',
        agreedAmount: 1500.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      );
      await repo.createBooking(existingBooking);

      // 2. Synthesize booking for the same worker on the same date
      final job = JobPost(
        id: '00000000-0000-0000-0000-000000000102',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Babar Khan',
        title: 'Afternoon Pipe Replacement',
        serviceCategory: 'Plumber',
        description: 'Replace main valve',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.19,
        longitude: 73.23,
        budget: 3000.0,
        requiredDate: targetDate,
        status: 'open',
        createdAt: DateTime.now(),
      );

      final app = JobApplication(
        id: 'app_adv_02',
        jobPostId: job.id,
        workerId: workerId,
        workerName: 'Rabia Bibi',
        workerRole: 'Plumber',
        workerRating: 4.8,
        proposedRate: 3200.0,
        notes: 'Ready',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      final synthesized = await repo.synthesizeConfirmedBooking(job: job, application: app);

      // Must have gracefully switched to afternoon slot 14:00 - 17:00
      expect(synthesized.startTime, const TimeOfDay(hour: 14, minute: 0));
      expect(synthesized.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(synthesized.agreedAmount, 3200.0);
      expect(synthesized.status, 'Accepted');
    });

    test('ADV-BKG-03: Double conflict in both morning and afternoon throws BookingConflictException', () async {
      final repo = BookingRepository();
      repo.reset();

      final targetDate = DateTime(2026, 12, 12);
      const workerId = '00000000-0000-0000-0000-000000000010';

      // 1. Occupy morning slot (9:00 - 12:00)
      await repo.createBooking(Booking(
        id: '00000000-0000-0000-0000-000000000991',
        householdId: '00000000-0000-0000-0000-000000000002',
        workerId: workerId,
        serviceCategoryId: 'Plumber',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Mandian',
        notes: 'Morning shift',
        agreedAmount: 2000.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      ));

      // 2. Occupy afternoon slot (14:00 - 17:00)
      await repo.createBooking(Booking(
        id: '00000000-0000-0000-0000-000000000992',
        householdId: '00000000-0000-0000-0000-000000000003',
        workerId: workerId,
        serviceCategoryId: 'Plumber',
        bookingDate: targetDate,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        address: 'Mandian',
        notes: 'Afternoon shift',
        agreedAmount: 2000.0,
        status: 'Accepted',
        createdAt: DateTime.now(),
      ));

      // 3. Synthesizing for this worker on this day must throw BookingConflictException
      final job = JobPost(
        id: '00000000-0000-0000-0000-000000000103',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Babar Khan',
        title: 'Emergency Drainage',
        serviceCategory: 'Plumber',
        description: 'Drain blocked',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.19,
        longitude: 73.23,
        budget: 4000.0,
        requiredDate: targetDate,
        status: 'open',
        createdAt: DateTime.now(),
      );

      final app = JobApplication(
        id: 'app_adv_03',
        jobPostId: job.id,
        workerId: workerId,
        workerName: 'Rabia Bibi',
        workerRole: 'Plumber',
        workerRating: 4.8,
        proposedRate: 4000.0,
        notes: '',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      expect(
        () => repo.synthesizeConfirmedBooking(job: job, application: app),
        throwsA(isA<BookingConflictException>()),
      );
    });

    test('ADV-BKG-04: Adversarial rates: negative rate falls back to budget, zero rates, extreme values', () async {
      final repo = BookingRepository();
      repo.reset();

      final job = JobPost(
        id: 'job_rate_test',
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Babar',
        title: 'Electrical Rewiring',
        serviceCategory: 'Electrician',
        description: 'Wiring check',
        city: 'Abbottabad',
        area: 'Supply',
        latitude: 34.19,
        longitude: 73.23,
        budget: 7500.0,
        requiredDate: DateTime(2026, 12, 15),
        status: 'open',
        createdAt: DateTime.now(),
      );

      // Subtest 1: Negative proposed rate (adversarial)
      final appNegative = JobApplication(
        id: 'app_neg',
        jobPostId: job.id,
        workerId: '00000000-0000-0000-0000-000000000013',
        workerName: 'Tariq',
        workerRole: 'Electrician',
        workerRating: 4.5,
        proposedRate: -500.0,
        notes: 'Malicious rate',
        status: 'pending',
        appliedAt: DateTime.now(),
      );
      final b1 = await repo.synthesizeConfirmedBooking(job: job, application: appNegative);
      expect(b1.agreedAmount, 7500.0, reason: 'Negative proposed rate must fall back to job budget');

      // Subtest 2: Zero budget and zero proposed rate
      final jobZero = job.copyWith(id: 'job_zero', budget: 0.0, requiredDate: DateTime(2026, 12, 16));
      final appZero = appNegative.copyWith(id: 'app_zero', proposedRate: 0.0);
      final b2 = await repo.synthesizeConfirmedBooking(job: jobZero, application: appZero);
      expect(b2.agreedAmount, 0.0);

      // Subtest 3: Extreme high rate (100 million PKR)
      final appHuge = appNegative.copyWith(id: 'app_huge', proposedRate: 100000000.0);
      final jobHuge = job.copyWith(id: 'job_huge', requiredDate: DateTime(2026, 12, 17));
      final b3 = await repo.synthesizeConfirmedBooking(job: jobHuge, application: appHuge);
      expect(b3.agreedAmount, 100000000.0);
    });

    test('ADV-BKG-05: UUID vs Legacy Job ID determines synthesized booking ID format and RFC 4122 compliance', () async {
      final repo = BookingRepository();
      repo.reset();

      // Case A: Job has standard UUID
      const uuidJobId = '00000000-0000-0000-0000-000000000101';
      final jobUuid = JobPost(
        id: uuidJobId,
        householdId: '00000000-0000-0000-0000-000000000001',
        householdName: 'Babar',
        title: 'UUID Job',
        serviceCategory: 'Plumber',
        description: 'Test',
        city: 'Abbottabad',
        area: 'Mandian',
        latitude: 34.19,
        longitude: 73.23,
        budget: 2000.0,
        requiredDate: DateTime(2026, 12, 20),
        status: 'open',
        createdAt: DateTime.now(),
      );

      final app = JobApplication(
        id: 'app_uuid_test',
        jobPostId: uuidJobId,
        workerId: '00000000-0000-0000-0000-000000000010',
        workerName: 'Rabia',
        workerRole: 'Plumber',
        workerRating: 4.8,
        proposedRate: 2000.0,
        notes: '',
        status: 'pending',
        appliedAt: DateTime.now(),
      );

      final bUuid = await repo.synthesizeConfirmedBooking(job: jobUuid, application: app);
      expect(IdMapping.isUuid(bUuid.id), isTrue, reason: 'Synthesized booking from UUID job must be valid RFC 4122 UUID');

      // Case B: Job has legacy ID
      final jobLegacy = jobUuid.copyWith(id: 'job_legacy_99', requiredDate: DateTime(2026, 12, 21));
      final bLegacy = await repo.synthesizeConfirmedBooking(job: jobLegacy, application: app);
      expect(bLegacy.id.startsWith('bkg_'), isTrue, reason: 'Synthesized booking from legacy job must start with bkg_');
    });

    test('ADV-BKG-06: Booking.arrivalOtp bounds, determinism, and collision distribution over 1000 IDs', () {
      final base = Booking(
        id: '',
        householdId: '00000000-0000-0000-0000-000000000001',
        workerId: '00000000-0000-0000-0000-000000000010',
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime(2026, 11, 20),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        address: 'Mandian',
        notes: '',
        agreedAmount: 2200.0,
        status: 'Accepted',
        createdAt: DateTime(2026, 10, 1),
      );

      // Empty ID fallback to createdAt
      final emptyIdOtp = base.arrivalOtp;
      expect(emptyIdOtp.length, 4);
      expect(int.parse(emptyIdOtp), inInclusiveRange(1000, 9999));

      // Test 1000 distinct IDs for range invariant and distribution
      final otps = <String>{};
      for (int i = 0; i < 1000; i++) {
        final b = base.copyWith(id: '00000000-0000-0000-0000-${i.toString().padLeft(12, '0')}');
        final otp = b.arrivalOtp;
        expect(otp.length, 4);
        final numVal = int.tryParse(otp);
        expect(numVal, isNotNull);
        expect(numVal!, inInclusiveRange(1000, 9999));

        // Determinism check on each instance
        expect(b.arrivalOtp, otp);

        otps.add(otp);
      }

      // Across 1000 uniform inputs in range [1000, 9999], unique OTPs should be high (expect > 800)
      expect(otps.length, greaterThan(800), reason: 'Arrival OTPs should have healthy dispersion');
    });

    test('ADV-BKG-07: Rapid booking syntheses must generate unique booking IDs without collisions', () async {
      final repo = BookingRepository();
      repo.reset();

      const count = 10;
      final synthesizedBookings = <Booking>[];

      for (int i = 0; i < count; i++) {
        final job = JobPost(
          id: '00000000-0000-0000-0000-${i.toString().padLeft(12, '0')}',
          householdId: '00000000-0000-0000-0000-000000000001',
          householdName: 'Babar',
          title: 'Rapid Job $i',
          serviceCategory: 'Cleaner',
          description: 'Cleaning $i',
          city: 'Abbottabad',
          area: 'Mandian',
          latitude: 34.19,
          longitude: 73.23,
          budget: 2000.0,
          requiredDate: DateTime(2026, 12, 1 + i),
          status: 'open',
          createdAt: DateTime.now(),
        );

        final app = JobApplication(
          id: 'app_rapid_$i',
          jobPostId: job.id,
          workerId: '00000000-0000-0000-0000-${(100 + i).toString().padLeft(12, '0')}',
          workerName: 'Worker $i',
          workerRole: 'Cleaner',
          workerRating: 4.8,
          proposedRate: 2000.0,
          notes: '',
          status: 'pending',
          appliedAt: DateTime.now(),
        );

        final booking = await repo.synthesizeConfirmedBooking(job: job, application: app);
        synthesizedBookings.add(booking);
      }

      final ids = synthesizedBookings.map((b) => b.id).toSet();
      expect(
        ids.length,
        count,
        reason: 'Every synthesized booking must have a unique ID; rapid generation collided!',
      );
    });
  });
}
