import 'package:flutter_test/flutter_test.dart';

import 'package:homeease/services/booking_repository.dart';
import 'package:homeease/widgets/payment_gateway_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CHALLENGER STRESS SUITE: Milestone 1 Payment & Deterministic Fallback', () {
    // =========================================================================
    // 1. LUHN 10 ALGORITHM ADVERSARIAL ATTACK
    // =========================================================================
    group('Attack 1: Luhn 10 Algorithm Adversarial Stress Testing', () {
      const validVisa = '4242424242424242';
      const validMastercard = '5555555555554444';
      const validTest1 = '4000000000000002';
      const validTest2 = '5105105105105100';

      test('ATTACK-LUHN-01: Baseline verification of known valid 16-digit cards', () {
        expect(PaymentGatewaySheet.isValidLuhn(validVisa), isTrue);
        expect(PaymentGatewaySheet.isValidLuhn(validMastercard), isTrue);
        expect(PaymentGatewaySheet.isValidLuhn(validTest1), isTrue);
        expect(PaymentGatewaySheet.isValidLuhn(validTest2), isTrue);
      });

      test('ATTACK-LUHN-02: Exhaustive single-digit corruption across all 16 positions', () {
        final cardsToTest = [validVisa, validMastercard, validTest1, validTest2];

        int totalMutations = 0;
        int detectedCorruptions = 0;

        for (final baseCard in cardsToTest) {
          for (int pos = 0; pos < 16; pos++) {
            final originalDigit = int.parse(baseCard[pos]);
            for (int replacement = 0; replacement <= 9; replacement++) {
              if (replacement == originalDigit) continue;

              final corrupted = baseCard.substring(0, pos) +
                  replacement.toString() +
                  baseCard.substring(pos + 1);

              totalMutations++;
              final isValid = PaymentGatewaySheet.isValidLuhn(corrupted);
              if (!isValid) {
                detectedCorruptions++;
              } else {
                fail(
                  'Luhn algorithm failed to reject single-digit mutation: '
                  'base=$baseCard pos=$pos original=$originalDigit mutated=$corrupted',
                );
              }
            }
          }
        }

        // Each card has 16 positions * 9 invalid replacements = 144 mutations
        // 4 cards * 144 = 576 corrupted variations
        expect(totalMutations, equals(576));
        expect(detectedCorruptions, equals(576));
      });

      test('ATTACK-LUHN-03: Adjacent digit transposition attack', () {
        // Transposing adjacent digits in 4242424242424242
        // Since digits alternate 4 and 2, every swap produces 24 instead of 42
        for (int i = 0; i < 15; i++) {
          final chars = validVisa.split('');
          final temp = chars[i];
          chars[i] = chars[i + 1];
          chars[i + 1] = temp;
          final transposed = chars.join();

          expect(
            PaymentGatewaySheet.isValidLuhn(transposed),
            isFalse,
            reason: 'Transposition at position $i and ${i + 1} was NOT detected in $transposed',
          );
        }

        // Boundary transposition between 5 and 4 in 5555555555554444
        final charsMc = validMastercard.split('');
        charsMc[11] = '4';
        charsMc[12] = '5';
        final transposedMc = charsMc.join();
        expect(PaymentGatewaySheet.isValidLuhn(transposedMc), isFalse);
      });

      test('ATTACK-LUHN-04: Odd-length and variable-length string attack', () {
        // Must reject any length != 16
        final oddLengths = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 25, 31];
        for (final len in oddLengths) {
          final candidate = '4' * len;
          expect(
            PaymentGatewaySheet.isValidLuhn(candidate),
            isFalse,
            reason: 'Odd-length string of length $len was not rejected',
          );
        }

        // Valid 15-digit Amex card should be rejected because platform expects 16-digit cards
        const amex15 = '378282246310005';
        expect(PaymentGatewaySheet.isValidLuhn(amex15), isFalse);

        // 13-digit legacy Visa
        const legacyVisa13 = '4111111111111';
        expect(PaymentGatewaySheet.isValidLuhn(legacyVisa13), isFalse);

        // 19-digit extended PAN
        const extendedPan19 = '4242424242424242000';
        expect(PaymentGatewaySheet.isValidLuhn(extendedPan19), isFalse);

        // Empty string
        expect(PaymentGatewaySheet.isValidLuhn(''), isFalse);
      });

      test('ATTACK-LUHN-05: Formatting resilience & edge cards', () {
        // Delimiters stripped correctly
        expect(PaymentGatewaySheet.isValidLuhn('4242 4242 4242 4242'), isTrue);
        expect(PaymentGatewaySheet.isValidLuhn('4242-4242-4242-4242'), isTrue);
        expect(PaymentGatewaySheet.isValidLuhn('4242.4242.4242.4242'), isTrue);
        expect(PaymentGatewaySheet.isValidLuhn('\t4242424242424242\n'), isTrue);
        expect(PaymentGatewaySheet.isValidLuhn('4242\u00A04242\u00A04242\u00A04242'), isTrue);

        // Edge cards
        expect(PaymentGatewaySheet.isValidLuhn('0000000000000000'), isTrue); // Sum = 0 % 10 == 0
        expect(PaymentGatewaySheet.isValidLuhn('9999999999999999'), isFalse); // Sum = 144 % 10 = 4 != 0

        // Alpha / special characters corrupted
        expect(PaymentGatewaySheet.isValidLuhn('424242424242424X'), isFalse);
        expect(PaymentGatewaySheet.isValidLuhn('XXXXXXXXXXXXXXXX'), isFalse);
        expect(PaymentGatewaySheet.isValidLuhn('4242 4242 4242 424'), isFalse); // 15 digits
      });
    });

    // =========================================================================
    // 2. PAKISTANI MOBILE NUMBER VALIDATOR ADVERSARIAL ATTACK
    // =========================================================================
    group('Attack 2: Pakistani Mobile Number Validator Adversarial Attack', () {
      test('ATTACK-PHONE-01: Invalid area & cellular prefixes rejection', () {
        final invalidPrefixNumbers = [
          '02112345678', // Karachi (021)
          '04212345678', // Lahore (042)
          '05112345678', // Islamabad/Rawalpindi (051)
          '09112345678', // Peshawar (091)
          '09921234567', // Abbottabad (0992)
          '08112345678', // Quetta (081)
          '06112345678', // Multan (061)
          '04112345678', // Faisalabad (041)
          '00123456789', // 00XX prefix
          '01123456789', // 01XX prefix
          '06123456789', // 06XX prefix
          '07123456789', // 07XX prefix
          '08123456789', // 08XX prefix
          '09123456789', // 09XX prefix
        ];

        for (final number in invalidPrefixNumbers) {
          expect(
            PaymentGatewaySheet.isValidPakistaniMobile(number),
            isFalse,
            reason: 'Number with invalid prefix $number was unexpectedly accepted',
          );
        }
      });

      test('ATTACK-PHONE-02: Valid 03XX cellular prefixes acceptance', () {
        final validPakistaniNumbers = [
          '03001234567', // Jazz
          '03123456789', // Zong
          '03219876543', // Warid
          '03335555555', // Ufone
          '03451112233', // Telenor
          '03551234567', // SCOM
          '03991234567',
        ];

        for (final number in validPakistaniNumbers) {
          expect(
            PaymentGatewaySheet.isValidPakistaniMobile(number),
            isTrue,
            reason: 'Valid cellular number $number was rejected',
          );
        }
      });

      test('ATTACK-PHONE-03: Length boundary attacks (10 digits, 12 digits, empty)', () {
        // 10 digits (missing last digit)
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0300123456'), isFalse);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0345987654'), isFalse);

        // 12 digits (extra trailing or leading digit)
        expect(PaymentGatewaySheet.isValidPakistaniMobile('030012345678'), isFalse);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('003001234567'), isFalse);

        // Extreme lengths
        expect(PaymentGatewaySheet.isValidPakistaniMobile(''), isFalse);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0'), isFalse);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('03'), isFalse);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0300123456703001234567'), isFalse);
      });

      test('ATTACK-PHONE-04: Letters, symbols, and non-breaking spaces', () {
        // Alpha injections
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0300123456A'), isFalse);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0300O123456'), isFalse); // Letter O
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0300l234567'), isFalse); // Letter l
        expect(PaymentGatewaySheet.isValidPakistaniMobile('03abcdefghi'), isFalse);

        // Non-breaking spaces and whitespace sanitization
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0300\u00A01234567'), isTrue);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('  03001234567  '), isTrue);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0300-123-4567'), isTrue);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('\t0300 1234567\n'), isTrue);

        // International format (app explicitly requires local 03XXXXXXXXX format)
        expect(PaymentGatewaySheet.isValidPakistaniMobile('+923001234567'), isFalse);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('00923001234567'), isFalse);

        // Malicious injection strings
        expect(PaymentGatewaySheet.isValidPakistaniMobile("0300'; DROP TABLE bookings;--"), isFalse);
        expect(PaymentGatewaySheet.isValidPakistaniMobile('0300<script>alert(1)</script>'), isFalse);
      });
    });

    // =========================================================================
    // 3. CARD EXPIRY PARSER ADVERSARIAL ATTACK
    // =========================================================================
    group('Attack 3: Card Expiry Parser Adversarial Attack', () {
      test('ATTACK-EXPIRY-01: Invalid months (00, 13..99)', () {
        expect(PaymentGatewaySheet.isValidExpiry('00/26'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('13/26'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('14/27'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('99/30'), isFalse);

        // Exhaustive check of months 0..99 with baseline year 26
        for (int m = 0; m <= 99; m++) {
          final mStr = m.toString().padLeft(2, '0');
          final input = '$mStr/26';
          final isValid = PaymentGatewaySheet.isValidExpiry(input);
          if (m >= 1 && m <= 12) {
            expect(isValid, isTrue, reason: 'Month $mStr should be valid');
          } else {
            expect(isValid, isFalse, reason: 'Month $mStr should be invalid');
          }
        }
      });

      test('ATTACK-EXPIRY-02: Past dates and boundary years (baseline 2026)', () {
        // Past years (< 26) must be rejected
        expect(PaymentGatewaySheet.isValidExpiry('12/25'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('01/25'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('06/24'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('12/20'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('12/00'), isFalse);

        // Current baseline year (26) must be accepted
        expect(PaymentGatewaySheet.isValidExpiry('01/26'), isTrue);
        expect(PaymentGatewaySheet.isValidExpiry('12/26'), isTrue);

        // Future years (>= 26) must be accepted
        expect(PaymentGatewaySheet.isValidExpiry('01/27'), isTrue);
        expect(PaymentGatewaySheet.isValidExpiry('07/30'), isTrue);
        expect(PaymentGatewaySheet.isValidExpiry('12/99'), isTrue);
      });

      test('ATTACK-EXPIRY-03: Malformed inputs, missing delimiters, and non-numeric values', () {
        expect(PaymentGatewaySheet.isValidExpiry('1226'), isTrue); // Cleaned digits = 1226, length 4
        expect(PaymentGatewaySheet.isValidExpiry('12 / 26'), isTrue);
        expect(PaymentGatewaySheet.isValidExpiry(' 12/26 '), isTrue);

        // Missing leading zero / wrong length
        expect(PaymentGatewaySheet.isValidExpiry('5/26'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('12/2026'), isFalse); // 4-digit year length = 6
        expect(PaymentGatewaySheet.isValidExpiry('12-26'), isFalse); // '-' not stripped, length = 5
        expect(PaymentGatewaySheet.isValidExpiry(''), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('ABCD'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('MM/YY'), isFalse);
        expect(PaymentGatewaySheet.isValidExpiry('!@#\$'), isFalse);
      });
    });

    // =========================================================================
    // 4. TXID GENERATION UNIQUENESS & ENTROPY HARNESS (1000 ITERATIONS)
    // =========================================================================
    group('Attack 4: TxID Generation Uniqueness & Entropy Stress Test', () {
      const iterations = 1000;

      test('ATTACK-TXID-01: 1000 Easypaisa TxIDs uniqueness and format (EP-XXXXXXXX)', () {
        final epSet = <String>{};
        final epPattern = RegExp(r'^EP-[0-9A-Z]{8}$');

        for (int i = 0; i < iterations; i++) {
          final txId = PaymentGatewaySheet.generateTxId(PaymentMode.easypaisa);
          expect(epPattern.hasMatch(txId), isTrue, reason: 'Invalid EP TxID format: $txId');
          expect(txId.length, equals(11));
          epSet.add(txId);
        }

        expect(
          epSet.length,
          equals(iterations),
          reason: 'Collision detected in Easypaisa TxID generation across $iterations iterations!',
        );
      });

      test('ATTACK-TXID-02: 1000 JazzCash TxIDs uniqueness and format (JC-XXXXXXXX)', () {
        final jcSet = <String>{};
        final jcPattern = RegExp(r'^JC-[0-9A-Z]{8}$');

        for (int i = 0; i < iterations; i++) {
          final txId = PaymentGatewaySheet.generateTxId(PaymentMode.jazzcash);
          expect(jcPattern.hasMatch(txId), isTrue, reason: 'Invalid JC TxID format: $txId');
          expect(txId.length, equals(11));
          jcSet.add(txId);
        }

        expect(
          jcSet.length,
          equals(iterations),
          reason: 'Collision detected in JazzCash TxID generation across $iterations iterations!',
        );
      });

      test('ATTACK-TXID-03: 1000 Stripe TxIDs uniqueness and format (ch_3M...)', () {
        final stripeSet = <String>{};
        final stripePattern = RegExp(r'^ch_3M[0-9A-Z]{21}$');

        for (int i = 0; i < iterations; i++) {
          final txId = PaymentGatewaySheet.generateTxId(PaymentMode.stripe);
          expect(stripePattern.hasMatch(txId), isTrue, reason: 'Invalid Stripe TxID format: $txId');
          expect(txId.length, equals(26));
          stripeSet.add(txId);
        }

        expect(
          stripeSet.length,
          equals(iterations),
          reason: 'Collision detected in Stripe TxID generation across $iterations iterations!',
        );
      });

      test('ATTACK-TXID-04: 1000 Cash on Delivery TxIDs uniqueness and format (COD-XXXXXXXX)', () {
        final codSet = <String>{};
        final codPattern = RegExp(r'^COD-[0-9A-Z]{8}$');

        for (int i = 0; i < iterations; i++) {
          final txId = PaymentGatewaySheet.generateTxId(PaymentMode.cod);
          expect(codPattern.hasMatch(txId), isTrue, reason: 'Invalid COD TxID format: $txId');
          expect(txId.length, equals(12));
          codSet.add(txId);
        }

        expect(
          codSet.length,
          equals(iterations),
          reason: 'Collision detected in COD TxID generation across $iterations iterations!',
        );
      });

      test('ATTACK-TXID-05: 4000 total multi-mode TxIDs disjointness and character set entropy', () {
        final allTxIds = <String>{};
        final modes = [
          PaymentMode.easypaisa,
          PaymentMode.jazzcash,
          PaymentMode.stripe,
          PaymentMode.cod,
        ];

        int digitCount = 0;
        int letterCount = 0;

        for (final mode in modes) {
          for (int i = 0; i < iterations; i++) {
            final txId = PaymentGatewaySheet.generateTxId(mode);
            allTxIds.add(txId);

            // Sample entropy of random characters (after prefix)
            final randomPart = mode == PaymentMode.stripe
                ? txId.substring(5)
                : txId.substring(txId.indexOf('-') + 1);

            for (final char in randomPart.codeUnits) {
              if (char >= 48 && char <= 57) digitCount++; // '0'-'9'
              if (char >= 65 && char <= 90) letterCount++; // 'A'-'Z'
            }
          }
        }

        // Across 4000 total iterations, all TxIDs must be mutually disjoint
        expect(allTxIds.length, equals(4000));

        // Entropy check: both digits and uppercase letters must be significantly present
        expect(digitCount, greaterThan(1000), reason: 'Insufficient numeric entropy in TxID generator');
        expect(letterCount, greaterThan(1000), reason: 'Insufficient alpha entropy in TxID generator');
      });
    });

    // =========================================================================
    // 5. COMPLETE BOOKING PAYMENT MISSING & CORRUPTED ID DETERMINISTIC FALLBACK
    // =========================================================================
    group('Attack 5: completeBookingPayment Deterministic Fallback Harness', () {
      late BookingRepository repo;

      setUp(() {
        repo = BookingRepository();
      });

      test('ATTACK-FALLBACK-01: Updating seeded existing booking successfully', () async {
        const seededId = '00000000-0000-0000-0000-000000000201';
        final updated = await repo.completeBookingPayment(
          bookingId: seededId,
          paymentMethod: 'Easypaisa',
          txId: 'EP-TEST0001',
          paymentStatus: 'confirmed',
        );

        expect(updated.id, equals(seededId));
        expect(updated.status, equals('Completed'));
        expect(updated.paymentStatus, equals('confirmed'));
        expect(updated.paymentMethod, equals('easypaisa'));
      });

      test('ATTACK-FALLBACK-02: Missing booking ID generates deterministic completed fallback', () async {
        const missingUuid = '99999999-9999-9999-9999-999999999999';
        final result = await repo.completeBookingPayment(
          bookingId: missingUuid,
          paymentMethod: 'JazzCash',
          txId: 'JC-FALLBACK99',
          paymentStatus: 'confirmed',
        );

        expect(result.id, equals(missingUuid));
        expect(result.status, equals('Completed'));
        expect(result.paymentStatus, equals('confirmed'));
        expect(result.paymentMethod, equals('jazzcash'));
        expect(result.notes, contains('JC-FALLBACK99'));
      });

      test('ATTACK-FALLBACK-03: Corrupted non-UUID booking ID survives without exception', () async {
        const corruptedId = 'bkg_corrupted_!@#\$%^&*()_+~`';
        final result = await repo.completeBookingPayment(
          bookingId: corruptedId,
          paymentMethod: 'Stripe',
          txId: 'ch_3M_CORRUPTED_TEST',
          paymentStatus: 'confirmed',
        );

        expect(result.id, equals(corruptedId));
        expect(result.status, equals('Completed'));
        expect(result.paymentStatus, equals('confirmed'));
        expect(result.paymentMethod, equals('stripe'));
        expect(result.notes, contains('ch_3M_CORRUPTED_TEST'));
      });

      test('ATTACK-FALLBACK-04: Empty string booking ID survives gracefully', () async {
        final result = await repo.completeBookingPayment(
          bookingId: '',
          paymentMethod: 'COD',
          txId: 'COD-EMPTY00',
        );

        expect(result.id, equals(''));
        expect(result.status, equals('Completed'));
        expect(result.paymentMethod, equals('cod'));
        expect(result.paymentStatus, equals('confirmed'));
      });

      test('ATTACK-FALLBACK-05: Idempotency under repeated completions with same ID', () async {
        const testId = 'idempotent-stress-test-id';

        final first = await repo.completeBookingPayment(
          bookingId: testId,
          paymentMethod: 'easypaisa',
          txId: 'EP-IDEM01',
        );

        final second = await repo.completeBookingPayment(
          bookingId: testId,
          paymentMethod: 'easypaisa',
          txId: 'EP-IDEM02',
        );

        expect(first.id, equals(testId));
        expect(second.id, equals(testId));
        expect(second.status, equals('Completed'));
        expect(second.paymentStatus, equals('confirmed'));
      });

      test('ATTACK-FALLBACK-06: Case normalization of irregular payment methods', () async {
        final result = await repo.completeBookingPayment(
          bookingId: 'case-test-id',
          paymentMethod: 'StRiPe_CrEdIt_CaRd',
          txId: 'ch_3M_CASE',
          paymentStatus: 'ESCROW_SETTLED',
        );

        expect(result.paymentMethod, equals('stripe_credit_card'));
        expect(result.paymentStatus, equals('ESCROW_SETTLED'));
      });
    });
  });
}
