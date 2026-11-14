import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

/// In-App Notification Center Service for HomeEase.
///
/// Features:
/// - Singleton ChangeNotifier pattern for reactive badge and feed updates.
/// - Live Supabase queries with seamless fallback to deterministic local mock notifications.
/// - Real-time bilingual support (English / Urdu) for domestic service events:
///   * Payment Sent / Escrow hold
///   * Booking Confirmed & schedule arrival
///   * Dispute updates & arbitration resolutions
///   * Worker NADRA CNIC verification status
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService({SupabaseClient? client}) {
    if (client != null) {
      _instance._customClient = client;
    }
    return _instance;
  }

  NotificationService._internal() {
    _initBaselineNotifications();
  }

  SupabaseClient? _customClient;
  final List<NotificationModel> _notifications = [];

  SupabaseClient? get client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void setClient(SupabaseClient? client) {
    _customClient = client;
  }

  void _initBaselineNotifications() {
    _notifications.clear();
    final now = DateTime.now();

    _notifications.addAll([
      NotificationModel(
        id: 'notif_001_payment',
        userId: 'h_1',
        title: 'Payment Sent — Escrow Secured',
        titleUrdu: 'ادائیگی بھیج دی گئی — رقم محفوظ ہے',
        message: 'PKR 2,200 via Easypaisa for Deep Cleaning has been placed in escrow hold.',
        messageUrdu: 'ڈیپ کلیننگ کے لیے ایزی پیسہ کے ذریعے 2,200 روپے ایسکرو ہولڈ میں محفوظ کر دیے گئے ہیں۔',
        type: 'Payment',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: 'notif_002_booking',
        userId: 'h_1',
        title: 'Booking Confirmed',
        titleUrdu: 'بکنگ کی تصدیق ہو گئی',
        message: 'Sana Gul accepted your domestic booking for Monday at 09:00 AM in Mandian.',
        messageUrdu: 'ثناء گل نے منڈیاں میں پیر کے روز صبح 09:00 بجے کی گھریلو سروس بکنگ قبول کر لی ہے۔',
        type: 'Booking',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'notif_003_dispute',
        userId: 'h_1',
        title: 'Dispute Update',
        titleUrdu: 'تنازعہ اپڈیٹ',
        message: 'Dispute #DISP-001 under review by Abbottabad arbitration desk.',
        messageUrdu: 'ایبٹ آباد ثالثی ڈیسک کی جانب سے شکایت #DISP-001 کا جائزہ لیا جا رہا ہے۔',
        type: 'Dispute',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: 'notif_004_verification',
        userId: 'w_1',
        title: 'Verification Status: Verified',
        titleUrdu: 'تصدیقی حیثیت: منظور شدہ',
        message: 'Your NADRA CNIC identity credentials have been verified by the administrator.',
        messageUrdu: 'انتظامیہ کی جانب سے آپ کے نادرا شناختی کارڈ کے کوائف کی تصدیق مکمل ہو گئی ہے۔',
        type: 'Verification',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  /// Unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Unmodifiable view of all notifications
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  /// Asynchronously fetches notifications from live Supabase if available,
  /// falling back gracefully to local cache when offline.
  Future<List<NotificationModel>> fetchNotifications({String? userId, String? role}) async {
    final sb = client;
    if (sb != null) {
      try {
        var query = sb.from('notifications').select('*');
        if (userId != null && userId.isNotEmpty) {
          query = query.or('user_id.eq.$userId,user_id.is.null');
        }
        final dynamic res = await query
            .order('created_at', ascending: false)
            .timeout(const Duration(milliseconds: 1200), onTimeout: () => []);
        final List<dynamic> rows = res as List<dynamic>;
        if (rows.isNotEmpty) {
          _notifications.clear();
          for (final row in rows) {
            _notifications.add(NotificationModel.fromMap(row as Map<String, dynamic>));
          }
          notifyListeners();
          return List.unmodifiable(_notifications);
        }
      } catch (e) {
        debugPrint('NotificationService.fetchNotifications error: $e. Falling back to local cache.');
      }
    }

    // Filter local notifications by userId if provided, or return all
    if (userId != null && userId.isNotEmpty) {
      final filtered = _notifications.where((n) => n.userId.isEmpty || n.userId == userId).toList();
      return List.unmodifiable(filtered);
    }

    return List.unmodifiable(_notifications);
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }

    final sb = client;
    if (sb != null) {
      try {
        await sb.from('notifications').update({'is_read': true}).eq('id', id);
      } catch (e) {
        debugPrint('NotificationService.markAsRead live error: $e');
      }
    }
  }

  /// Marks all current notifications as read.
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();

    final sb = client;
    if (sb != null) {
      try {
        await sb.from('notifications').update({'is_read': true}).filter('is_read', 'eq', false);
      } catch (e) {
        debugPrint('NotificationService.markAllAsRead live error: $e');
      }
    }
  }

  /// Clears all notifications.
  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
  }

  /// Adds a new notification to the active list and optionally inserts into Supabase.
  Future<NotificationModel> addNotification(NotificationModel notif) async {
    _notifications.insert(0, notif);
    notifyListeners();

    final sb = client;
    if (sb != null) {
      try {
        await sb.from('notifications').insert(notif.toMap());
      } catch (e) {
        debugPrint('NotificationService.addNotification live error: $e');
      }
    }
    return notif;
  }

  @visibleForTesting
  void reset() {
    _customClient = null;
    _initBaselineNotifications();
    notifyListeners();
  }

  @visibleForTesting
  static void resetInstance() {
    _instance.reset();
  }
}
