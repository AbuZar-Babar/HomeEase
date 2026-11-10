/// Bidirectional identity mapping between legacy mock string IDs
/// (e.g. 'worker_1', 'h_1', 'job_1', 'booking_1') and their canonical
/// PostgreSQL RFC 4122 UUID representations in the live Supabase database.
class IdMapping {
  static const Map<String, String> workerLegacyToUuid = {
    'worker_1': '00000000-0000-0000-0000-000000000010',
    'worker_2': '00000000-0000-0000-0000-000000000011',
    'worker_3': '00000000-0000-0000-0000-000000000012',
    'worker_4': '00000000-0000-0000-0000-000000000013',
    'worker_5': '00000000-0000-0000-0000-000000000014',
    'worker_6': '00000000-0000-0000-0000-000000000015',
    'worker_7': '00000000-0000-0000-0000-000000000016',
    'worker_8': '00000000-0000-0000-0000-000000000017',
    'worker_9': '00000000-0000-0000-0000-000000000018',
    'worker_10': '00000000-0000-0000-0000-000000000019',
    'worker_11': '00000000-0000-0000-0000-000000000020',
    'worker_12': '00000000-0000-0000-0000-000000000021',
    'w_rabia': '00000000-0000-0000-0000-000000000010',
    'w_sana': '00000000-0000-0000-0000-000000000012',
    'w_1': '00000000-0000-0000-0000-000000000010',
  };

  static const Map<String, String> householdLegacyToUuid = {
    'h_1': '00000000-0000-0000-0000-000000000001',
    'h_demo_1': '00000000-0000-0000-0000-000000000001',
    'household_1': '00000000-0000-0000-0000-000000000001',
    'h_babar': '00000000-0000-0000-0000-000000000001',
    'h_2': '00000000-0000-0000-0000-000000000002',
    'household_2': '00000000-0000-0000-0000-000000000002',
    'h_malik': '00000000-0000-0000-0000-000000000002',
    'h_3': '00000000-0000-0000-0000-000000000003',
    'household_3': '00000000-0000-0000-0000-000000000003',
    'h_tariq': '00000000-0000-0000-0000-000000000003',
    'h_4': '00000000-0000-0000-0000-000000000004',
    'household_4': '00000000-0000-0000-0000-000000000004',
    'h_saima': '00000000-0000-0000-0000-000000000004',
    'h_5': '00000000-0000-0000-0000-000000000005',
    'household_5': '00000000-0000-0000-0000-000000000005',
    'h_javed': '00000000-0000-0000-0000-000000000005',
    'h_6': '00000000-0000-0000-0000-000000000006',
    'household_6': '00000000-0000-0000-0000-000000000006',
    'h_bilqees': '00000000-0000-0000-0000-000000000006',
  };

  static const Map<String, String> jobLegacyToUuid = {
    'job_1': '00000000-0000-0000-0000-000000000101',
    'job_mkt_1': '00000000-0000-0000-0000-000000000101',
    'job_2': '00000000-0000-0000-0000-000000000102',
    'job_3': '00000000-0000-0000-0000-000000000103',
    'job_4': '00000000-0000-0000-0000-000000000104',
    'job_5': '00000000-0000-0000-0000-000000000105',
    'job_6': '00000000-0000-0000-0000-000000000106',
  };

  static const Map<String, String> bookingLegacyToUuid = {
    'booking_1': '00000000-0000-0000-0000-000000000201',
    'bkg_1': '00000000-0000-0000-0000-000000000201',
    'booking_2': '00000000-0000-0000-0000-000000000202',
    'bkg_2': '00000000-0000-0000-0000-000000000202',
    'booking_3': '00000000-0000-0000-0000-000000000203',
    'bkg_3': '00000000-0000-0000-0000-000000000203',
    'booking_4': '00000000-0000-0000-0000-000000000204',
    'bkg_4': '00000000-0000-0000-0000-000000000204',
  };

  /// Checks if a string is a standard RFC 4122 UUID.
  static bool isUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(str);
  }

  /// Maps worker ID (legacy or UUID) to canonical RFC 4122 UUID.
  static String toWorkerUuid(String id) {
    if (isUuid(id)) return id;
    return workerLegacyToUuid[id] ?? id;
  }

  /// Maps household ID (legacy or UUID) to canonical RFC 4122 UUID.
  static String toHouseholdUuid(String id) {
    if (isUuid(id)) return id;
    return householdLegacyToUuid[id] ?? id;
  }

  /// Maps job ID (legacy or UUID) to canonical RFC 4122 UUID.
  static String toJobUuid(String id) {
    if (isUuid(id)) return id;
    return jobLegacyToUuid[id] ?? id;
  }

  /// Maps booking ID (legacy or UUID) to canonical RFC 4122 UUID.
  static String toBookingUuid(String id) {
    if (isUuid(id)) return id;
    return bookingLegacyToUuid[id] ?? id;
  }

  /// Checks if two worker ID representations refer to the exact same worker.
  static bool matchesWorker(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    final uuidA = toWorkerUuid(a);
    final uuidB = toWorkerUuid(b);
    return uuidA == uuidB;
  }

  /// Checks if two household ID representations refer to the exact same household.
  static bool matchesHousehold(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    final uuidA = toHouseholdUuid(a);
    final uuidB = toHouseholdUuid(b);
    return uuidA == uuidB;
  }

  /// Checks if two job ID representations refer to the exact same job.
  static bool matchesJob(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    final uuidA = toJobUuid(a);
    final uuidB = toJobUuid(b);
    return uuidA == uuidB;
  }

  /// Checks if two booking ID representations refer to the exact same booking.
  static bool matchesBooking(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    final uuidA = toBookingUuid(a);
    final uuidB = toBookingUuid(b);
    return uuidA == uuidB;
  }
}
