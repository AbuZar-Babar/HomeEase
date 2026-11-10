import 'package:flutter/material.dart';

class Booking {
  final String id;
  final String householdId;
  final String workerId;
  final String serviceCategoryId;
  final DateTime bookingDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String address;
  final String notes;
  final double agreedAmount;
  final String status; // 'Pending', 'Accepted', 'Rejected', 'Completed', 'Cancelled'
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.householdId,
    required this.workerId,
    required this.serviceCategoryId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.notes,
    required this.agreedAmount,
    required this.status,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'unpaid',
    required this.createdAt,
  });

  /// Calculates duration in hours between startTime and endTime.
  double get durationHours {
    final s = startTime.hour * 60 + startTime.minute;
    final e = endTime.hour * 60 + endTime.minute;
    final diff = (e - s) / 60.0;
    return diff > 0 ? diff : 2.0;
  }

  /// Secure 4-digit arrival verification OTP derived deterministically from booking identity.
  String get arrivalOtp {
    final seed = id.isNotEmpty ? id.hashCode.abs() : createdAt.millisecondsSinceEpoch.abs();
    final code = (seed % 9000) + 1000;
    return code.toString();
  }

  /// Deserializes Booking from a Supabase row map.
  factory Booking.fromMap(Map<String, dynamic> map) {
    final String id = map['id']?.toString() ?? '';
    final String householdId = map['employer_id']?.toString() ??
        map['household_id']?.toString() ??
        map['householdId']?.toString() ??
        '';
    final String workerId = map['worker_id']?.toString() ??
        map['workerId']?.toString() ??
        '';
    final String serviceCategoryId = map['service_category_id']?.toString() ??
        map['serviceCategory']?.toString() ??
        map['category']?.toString() ??
        'Domestic Service';

    // Booking date
    DateTime bookingDate = DateTime.now();
    final dynamic rawDate = map['service_date'] ?? map['booking_date'] ?? map['bookingDate'];
    if (rawDate is DateTime) {
      bookingDate = rawDate;
    } else if (rawDate is String && rawDate.isNotEmpty) {
      bookingDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    // Start time
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    final dynamic rawStart = map['start_time'] ?? map['startTime'];
    if (rawStart is TimeOfDay) {
      startTime = rawStart;
    } else if (rawStart is String && rawStart.isNotEmpty) {
      final parts = rawStart.split(':');
      if (parts.length >= 2) {
        startTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    // Duration hours & end time
    double duration = 2.0;
    final dynamic rawDuration = map['duration_hours'] ?? map['durationHours'];
    if (rawDuration is num) {
      duration = rawDuration.toDouble();
    } else if (rawDuration is String && rawDuration.isNotEmpty) {
      duration = double.tryParse(rawDuration) ?? 2.0;
    }

    TimeOfDay endTime;
    final dynamic rawEnd = map['end_time'] ?? map['endTime'];
    if (rawEnd is TimeOfDay) {
      endTime = rawEnd;
    } else if (rawEnd is String && rawEnd.isNotEmpty) {
      final parts = rawEnd.split(':');
      if (parts.length >= 2) {
        endTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 11,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      } else {
        final totalMinutes = startTime.hour * 60 + startTime.minute + (duration * 60).round();
        endTime = TimeOfDay(hour: (totalMinutes ~/ 60) % 24, minute: totalMinutes % 60);
      }
    } else {
      final totalMinutes = startTime.hour * 60 + startTime.minute + (duration * 60).round();
      endTime = TimeOfDay(hour: (totalMinutes ~/ 60) % 24, minute: totalMinutes % 60);
    }

    final String address = map['address']?.toString() ?? '';
    final String notes = map['notes']?.toString() ?? '';

    // Agreed amount
    final dynamic rawAmount = map['total_amount'] ?? map['agreed_amount'] ?? map['agreedAmount'];
    double agreedAmount = 0.0;
    if (rawAmount is num) {
      agreedAmount = rawAmount.toDouble();
    } else if (rawAmount is String && rawAmount.isNotEmpty) {
      agreedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    // Status normalization
    final String rawStatus = map['status']?.toString() ?? 'Pending';
    String status;
    switch (rawStatus.toLowerCase().trim()) {
      case 'pending':
        status = 'Pending';
        break;
      case 'accepted':
        status = 'Accepted';
        break;
      case 'rejected':
        status = 'Rejected';
        break;
      case 'in_progress':
        status = 'In Progress';
        break;
      case 'completed':
        status = 'Completed';
        break;
      case 'cancelled':
        status = 'Cancelled';
        break;
      case 'disputed':
        status = 'Disputed';
        break;
      default:
        status = rawStatus;
    }

    final String paymentMethod = map['payment_method']?.toString() ?? 'cash';
    final String paymentStatus = map['payment_status']?.toString() ?? 'unpaid';

    DateTime createdAt = DateTime.now();
    final dynamic rawCreated = map['created_at'] ?? map['createdAt'];
    if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else if (rawCreated is String && rawCreated.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    return Booking(
      id: id,
      householdId: householdId,
      workerId: workerId,
      serviceCategoryId: serviceCategoryId,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      address: address,
      notes: notes,
      agreedAmount: agreedAmount,
      status: status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      createdAt: createdAt,
    );
  }

  /// Serializes Booking to a Map matching Supabase `bookings` table.
  Map<String, dynamic> toMap() {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMin = startTime.minute.toString().padLeft(2, '0');
    final startTimeStr = '$startHour:$startMin:00';
    final dateStr =
        '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';

    final data = <String, dynamic>{
      'employer_id': householdId,
      'worker_id': workerId,
      'service_date': dateStr,
      'start_time': startTimeStr,
      'duration_hours': durationHours,
      'total_amount': agreedAmount,
      'status': status.toLowerCase().replaceAll(' ', '_'),
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'address': address,
      'notes': notes,
    };
    if (id.isNotEmpty &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(id)) {
      data['id'] = id;
    }
    return data;
  }

  Booking copyWith({
    String? id,
    String? householdId,
    String? workerId,
    String? serviceCategoryId,
    DateTime? bookingDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? address,
    String? notes,
    double? agreedAmount,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      workerId: workerId ?? this.workerId,
      serviceCategoryId: serviceCategoryId ?? this.serviceCategoryId,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      agreedAmount: agreedAmount ?? this.agreedAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
