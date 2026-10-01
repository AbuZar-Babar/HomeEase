import 'package:flutter/material.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String role; // 'Household', 'Worker', 'Admin'
  final String accountStatus;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    required this.accountStatus,
    required this.createdAt,
  });
}

class HouseholdProfile {
  final String id;
  final String address;
  final String city;
  final String area;
  final String servicePreferences;

  HouseholdProfile({
    required this.id,
    required this.address,
    required this.city,
    required this.area,
    required this.servicePreferences,
  });
}

class WorkerProfile {
  final String id;
  final String name; // maps to user.fullName
  final String role; // maps to worker service category / role description
  final double rating; // maps to averageRating
  final String rate; // maps to worker service expected charges
  final String experience; // maps to experienceYears
  final String availability; // maps to availabilityStatus
  final String location; // maps to city/area
  final String description; // maps to bio
  final String highlight; // maps to verificationStatus / custom highlight

  // Class diagram fields
  final String bio;
  final int experienceYears;
  final String city;
  final String area;
  final String availabilityStatus;
  final String verificationStatus; // 'PendingVerification', 'Verified', 'RejectedVerification'
  final double averageRating;
  final bool profileVisibility;
  final double latitude;
  final double longitude;
  final List<String> skillTags;
  final int reviewsCount;
  final String? avatarUrl;
  final String? phone;
  final double hourlyRate;

  const WorkerProfile({
    this.id = '',
    required this.name,
    required this.role,
    required this.rating,
    required this.rate,
    required this.experience,
    required this.availability,
    required this.location,
    required this.description,
    required this.highlight,
    this.bio = '',
    this.experienceYears = 0,
    this.city = 'Abbottabad',
    this.area = '',
    this.availabilityStatus = 'Available',
    this.verificationStatus = 'Verified',
    this.averageRating = 0.0,
    this.profileVisibility = true,
    this.latitude = 34.1983,
    this.longitude = 73.2425,
    this.skillTags = const [],
    this.reviewsCount = 12,
    this.avatarUrl,
    this.phone,
    this.hourlyRate = 0.0,
  });

  /// Factory constructor to deserialize WorkerProfile from Supabase PostgREST responses.
  /// Handles joined `profiles` table attributes (`full_name`, `avatar_url`, `phone`, `email`)
  /// along with `worker_profiles` columns (`skills`, `hourly_rate`, `locality`, etc.).
  factory WorkerProfile.fromMap(Map<String, dynamic> map) {
    // 1. Resolve joined profile attributes (handles single map, list with map, or profile alias)
    Map<String, dynamic>? profileMap;
    if (map['profiles'] is Map<String, dynamic>) {
      profileMap = map['profiles'] as Map<String, dynamic>;
    } else if (map['profiles'] is List &&
        (map['profiles'] as List).isNotEmpty &&
        (map['profiles'] as List).first is Map) {
      profileMap = (map['profiles'] as List).first as Map<String, dynamic>;
    } else if (map['profile'] is Map<String, dynamic>) {
      profileMap = map['profile'] as Map<String, dynamic>;
    }

    // 2. Identify Worker ID and Identity
    final String id = map['id']?.toString() ?? profileMap?['id']?.toString() ?? '';
    final String name = profileMap?['full_name']?.toString() ??
        profileMap?['name']?.toString() ??
        map['full_name']?.toString() ??
        map['name']?.toString() ??
        'Domestic Worker';
    final String? avatarUrl = profileMap?['avatar_url']?.toString() ?? map['avatar_url']?.toString();
    final String? phone = profileMap?['phone']?.toString() ?? map['phone']?.toString();

    // 3. Hourly Rate & Display Rate String
    final dynamic rawRate = map['hourly_rate'] ?? map['hourlyRate'] ?? map['rate'];
    double hourlyRate = 0.0;
    if (rawRate is num) {
      hourlyRate = rawRate.toDouble();
    } else if (rawRate is String && rawRate.isNotEmpty) {
      final sanitized = rawRate.replaceAll(RegExp(r'[^0-9.]'), '');
      hourlyRate = double.tryParse(sanitized) ?? 0.0;
    }
    final String rateStr = map['rate']?.toString() ??
        (hourlyRate > 0 ? 'PKR ${hourlyRate.toInt()} / hr' : 'PKR 1,500 / hr');

    // 4. Skills & Trade Role
    List<String> skillTags = [];
    final dynamic rawSkills = map['skills'] ?? map['skill_tags'] ?? map['skillTags'];
    if (rawSkills is List) {
      skillTags = rawSkills.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (rawSkills is String && rawSkills.isNotEmpty) {
      skillTags = rawSkills.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
    }

    String role = map['role']?.toString() ?? '';
    if (role.isEmpty) {
      const knownTrades = [
        'Cook',
        'Cleaner',
        'Nanny',
        'Caregiver',
        'Maid',
        'Electrician',
        'Plumber',
        'Painter',
        'Carpenter'
      ];
      for (final trade in knownTrades) {
        if (skillTags.any((s) => s.toLowerCase() == trade.toLowerCase() || s.toLowerCase().contains(trade.toLowerCase()))) {
          role = trade;
          break;
        }
      }
      if (role.isEmpty && skillTags.isNotEmpty) {
        role = skillTags.first;
      }
      if (role.isEmpty) {
        role = 'Domestic Worker';
      }
    }

    // 5. Experience
    final dynamic rawExp = map['experience_years'] ?? map['experienceYears'] ?? map['experience'];
    int experienceYears = 0;
    if (rawExp is num) {
      experienceYears = rawExp.toInt();
    } else if (rawExp is String && rawExp.isNotEmpty) {
      final sanitized = rawExp.replaceAll(RegExp(r'[^0-9]'), '');
      experienceYears = int.tryParse(sanitized) ?? 0;
    }
    final String experienceStr = map['experience']?.toString() ??
        '$experienceYears ${experienceYears == 1 ? 'year' : 'years'}';

    // 6. Rating & Reviews Count
    final dynamic rawRating = map['rating'] ?? map['average_rating'] ?? map['averageRating'];
    double rating = 0.0;
    if (rawRating is num) {
      rating = rawRating.toDouble();
    } else if (rawRating is String && rawRating.isNotEmpty) {
      rating = double.tryParse(rawRating) ?? 0.0;
    }

    final dynamic rawReviews = map['reviews_count'] ?? map['reviewsCount'];
    int reviewsCount = 0;
    if (rawReviews is num) {
      reviewsCount = rawReviews.toInt();
    } else if (rawReviews is String && rawReviews.isNotEmpty) {
      reviewsCount = int.tryParse(rawReviews) ?? 0;
    }

    // 7. Location, City, Locality, Coordinates
    final String locality = map['locality']?.toString() ??
        map['area']?.toString() ??
        map['location']?.toString() ??
        'Mandian';
    final String city = map['city']?.toString() ?? 'Abbottabad';
    final String location = map['location']?.toString() ?? locality;
    final String area = map['area']?.toString() ?? locality;

    final dynamic rawLat = map['latitude'] ?? map['lat'];
    final double latitude = rawLat is num
        ? rawLat.toDouble()
        : (rawLat is String ? (double.tryParse(rawLat) ?? 34.1983) : 34.1983);

    final dynamic rawLon = map['longitude'] ?? map['lon'] ?? map['lng'];
    final double longitude = rawLon is num
        ? rawLon.toDouble()
        : (rawLon is String ? (double.tryParse(rawLon) ?? 73.2425) : 73.2425);

    // 8. Verification Status & Highlight
    final bool isVerified = map['verified'] == true ||
        map['verification_status'] == 'Verified' ||
        map['verificationStatus'] == 'Verified';
    final String verificationStatus = map['verification_status']?.toString() ??
        map['verificationStatus']?.toString() ??
        (isVerified ? 'Verified' : 'PendingVerification');
    final String highlight = map['highlight']?.toString() ?? (isVerified ? 'Verified' : 'Available');

    // 9. Availability
    String availabilityStatus = 'Available today';
    final dynamic rawAvail = map['availability'] ?? map['availability_status'] ?? map['availabilityStatus'];
    if (rawAvail is Map && rawAvail['status'] != null) {
      availabilityStatus = rawAvail['status'].toString();
    } else if (rawAvail is String && rawAvail.isNotEmpty) {
      availabilityStatus = rawAvail;
    }
    final String availability = map['availability'] is String
        ? (map['availability'] as String)
        : availabilityStatus;

    // 10. Bio & Description
    final String bio = map['bio']?.toString() ?? map['description']?.toString() ?? '';
    final String description = map['description']?.toString() ?? bio;

    // 11. Profile Visibility
    final bool profileVisibility = map['profile_visibility'] == true ||
        map['profileVisibility'] == true ||
        map['profile_visibility'] == null;

    return WorkerProfile(
      id: id,
      name: name,
      role: role,
      rating: rating,
      rate: rateStr,
      experience: experienceStr,
      availability: availability,
      location: location,
      description: description,
      highlight: highlight,
      bio: bio,
      experienceYears: experienceYears,
      city: city,
      area: area,
      availabilityStatus: availabilityStatus,
      verificationStatus: verificationStatus,
      averageRating: rating,
      profileVisibility: profileVisibility,
      latitude: latitude,
      longitude: longitude,
      skillTags: skillTags,
      reviewsCount: reviewsCount,
      avatarUrl: avatarUrl,
      phone: phone,
      hourlyRate: hourlyRate,
    );
  }

  /// Serializes WorkerProfile to a Map representation matching Supabase schema.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skills': skillTags,
      'experience_years': experienceYears,
      'hourly_rate': hourlyRate > 0
          ? hourlyRate
          : (double.tryParse(rate.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0),
      'locality': area.isNotEmpty ? area : location,
      'bio': bio.isNotEmpty ? bio : description,
      'rating': rating,
      'reviews_count': reviewsCount,
      'verified': verificationStatus == 'Verified',
      'availability': {
        'status': availabilityStatus.isNotEmpty ? availabilityStatus : availability,
        'slots': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      },
      'latitude': latitude,
      'longitude': longitude,
      'profile_visibility': profileVisibility,
      'profiles': {
        'id': id,
        'full_name': name,
        'email': '$id@homeease.com',
        'phone': phone ?? '+923000000000',
        'role': 'worker',
        'avatar_url': avatarUrl,
      },
    };
  }

  WorkerProfile copyWith({
    String? id,
    String? name,
    String? role,
    double? rating,
    String? rate,
    String? experience,
    String? availability,
    String? location,
    String? description,
    String? highlight,
    String? bio,
    int? experienceYears,
    String? city,
    String? area,
    String? availabilityStatus,
    String? verificationStatus,
    double? averageRating,
    bool? profileVisibility,
    double? latitude,
    double? longitude,
    List<String>? skillTags,
    int? reviewsCount,
    String? avatarUrl,
    String? phone,
    double? hourlyRate,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      rate: rate ?? this.rate,
      experience: experience ?? this.experience,
      availability: availability ?? this.availability,
      location: location ?? this.location,
      description: description ?? this.description,
      highlight: highlight ?? this.highlight,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      city: city ?? this.city,
      area: area ?? this.area,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      averageRating: averageRating ?? this.averageRating,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      skillTags: skillTags ?? this.skillTags,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }
}

class ServiceCategory {
  final String id;
  final String name;
  final String description;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
  });
}

class WorkerService {
  final String id;
  final String workerId;
  final String serviceCategoryId;
  final double rate;
  final String rateUnit;

  WorkerService({
    required this.id,
    required this.workerId,
    required this.serviceCategoryId,
    required this.rate,
    required this.rateUnit,
  });
}

class AvailabilitySlot {
  final String id;
  final String workerId;
  final String dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;

  AvailabilitySlot({
    required this.id,
    required this.workerId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });
}

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

class ServiceAgreement {
  final String id;
  final String bookingId;
  final String householdId;
  final String workerId;
  final String serviceCategoryId;
  final String agreementText;
  final double agreedAmount;
  final String terms;
  final String status;
  final DateTime generatedAt;

  ServiceAgreement({
    required this.id,
    required this.bookingId,
    required this.householdId,
    required this.workerId,
    required this.serviceCategoryId,
    required this.agreementText,
    required this.agreedAmount,
    required this.terms,
    required this.status,
    required this.generatedAt,
  });
}

class PaymentRecord {
  final String id;
  final String bookingId;
  final String householdId;
  final String workerId;
  final double amount;
  final String paymentMethod;
  final String receiverAccountTitle;
  final String receiverAccountNumber;
  final String receiptURL;
  final String transactionNote;
  final String status; // 'Submitted', 'Confirmed', 'Disputed', 'Cancelled'
  final DateTime submittedAt;
  final DateTime? confirmedAt;

  PaymentRecord({
    required this.id,
    required this.bookingId,
    required this.householdId,
    required this.workerId,
    required this.amount,
    required this.paymentMethod,
    required this.receiverAccountTitle,
    required this.receiverAccountNumber,
    required this.receiptURL,
    required this.transactionNote,
    required this.status,
    required this.submittedAt,
    this.confirmedAt,
  });
}

class Review {
  final String id;
  final String bookingId;
  final String householdId;
  final String workerId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.householdId,
    required this.workerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });
}

class VerificationRequest {
  final String id;
  final String workerId;
  final String submittedDetails;
  final String status; // 'PendingVerification', 'Verified', 'RejectedVerification'
  final String? adminId;
  final String rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  VerificationRequest({
    required this.id,
    required this.workerId,
    required this.submittedDetails,
    required this.status,
    this.adminId,
    required this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
  });
}

class Dispute {
  final String id;
  final String bookingId;
  final String paymentRecordId;
  final String raisedBy;
  final String againstUserId;
  final String category;
  final String description;
  final String evidenceURL;
  final String status; // 'OpenDispute', 'InReview', 'Resolved', 'RejectedDispute'
  final String? adminId;
  final String adminRemarks;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Dispute({
    required this.id,
    required this.bookingId,
    required this.paymentRecordId,
    required this.raisedBy,
    required this.againstUserId,
    required this.category,
    required this.description,
    required this.evidenceURL,
    required this.status,
    this.adminId,
    required this.adminRemarks,
    required this.createdAt,
    this.resolvedAt,
  });
}

class IssueReport {
  final String id;
  final String reporterId;
  final String relatedBookingId;
  final String message;
  final String status;
  final DateTime createdAt;

  IssueReport({
    required this.id,
    required this.reporterId,
    required this.relatedBookingId,
    required this.message,
    required this.status,
    required this.createdAt,
  });
}

class JobPost {
  final String id;
  final String householdId;
  final String householdName;
  final String title;
  final String serviceCategory;
  final String description;
  final String city;
  final String area;
  final double latitude;
  final double longitude;
  final double budget;
  final DateTime requiredDate;
  final String status; // 'open', 'assigned', 'completed', 'cancelled'
  final DateTime createdAt;

  JobPost({
    required this.id,
    required this.householdId,
    required this.householdName,
    required this.title,
    required this.serviceCategory,
    required this.description,
    required this.city,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.budget,
    required this.requiredDate,
    required this.status,
    required this.createdAt,
  });

  /// Deserializes JobPost from a Supabase row map.
  /// Handles joined `profiles` for employer name.
  factory JobPost.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? profileMap;
    if (map['profiles'] is Map<String, dynamic>) {
      profileMap = map['profiles'] as Map<String, dynamic>;
    } else if (map['profiles'] is List &&
        (map['profiles'] as List).isNotEmpty &&
        (map['profiles'] as List).first is Map) {
      profileMap = (map['profiles'] as List).first as Map<String, dynamic>;
    }

    final String id = map['id']?.toString() ?? '';
    final String householdId = map['employer_id']?.toString() ??
        map['household_id']?.toString() ??
        map['householdId']?.toString() ??
        '';
    final String householdName = profileMap?['full_name']?.toString() ??
        map['household_name']?.toString() ??
        map['householdName']?.toString() ??
        'Household Employer';
    final String title = map['title']?.toString() ?? '';
    final String serviceCategory = map['category']?.toString() ??
        map['service_category']?.toString() ??
        map['serviceCategory']?.toString() ??
        'Cook';
    final String description = map['description']?.toString() ?? '';
    final String city = map['city']?.toString() ?? 'Abbottabad';
    final String area = map['locality']?.toString() ??
        map['area']?.toString() ??
        'Mandian';

    final dynamic rawLat = map['latitude'] ?? map['lat'];
    final double latitude = rawLat is num
        ? rawLat.toDouble()
        : (rawLat is String ? (double.tryParse(rawLat) ?? 34.1983) : 34.1983);

    final dynamic rawLon = map['longitude'] ?? map['lon'] ?? map['lng'];
    final double longitude = rawLon is num
        ? rawLon.toDouble()
        : (rawLon is String ? (double.tryParse(rawLon) ?? 73.2425) : 73.2425);

    final dynamic rawBudget = map['budget'];
    double budget = 0.0;
    if (rawBudget is num) {
      budget = rawBudget.toDouble();
    } else if (rawBudget is String && rawBudget.isNotEmpty) {
      budget = double.tryParse(rawBudget) ?? 0.0;
    }

    DateTime requiredDate = DateTime.now();
    final dynamic rawDate = map['date'] ?? map['required_date'] ?? map['requiredDate'];
    if (rawDate is DateTime) {
      requiredDate = rawDate;
    } else if (rawDate is String && rawDate.isNotEmpty) {
      requiredDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    final String status = map['status']?.toString() ?? 'open';

    DateTime createdAt = DateTime.now();
    final dynamic rawCreated = map['created_at'] ?? map['createdAt'];
    if (rawCreated is DateTime) {
      createdAt = rawCreated;
    } else if (rawCreated is String && rawCreated.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    return JobPost(
      id: id,
      householdId: householdId,
      householdName: householdName,
      title: title,
      serviceCategory: serviceCategory,
      description: description,
      city: city,
      area: area,
      latitude: latitude,
      longitude: longitude,
      budget: budget,
      requiredDate: requiredDate,
      status: status,
      createdAt: createdAt,
    );
  }

  /// Serializes JobPost to a Map matching Supabase `jobs` table schema.
  Map<String, dynamic> toMap() {
    final dateStr =
        '${requiredDate.year}-${requiredDate.month.toString().padLeft(2, '0')}-${requiredDate.day.toString().padLeft(2, '0')}';
    final data = <String, dynamic>{
      'employer_id': householdId,
      'title': title,
      'category': serviceCategory,
      'description': description,
      'locality': area,
      'latitude': latitude,
      'longitude': longitude,
      'date': dateStr,
      'budget': budget,
      'status': status.toLowerCase(),
    };
    if (id.isNotEmpty &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(id)) {
      data['id'] = id;
    }
    return data;
  }

  JobPost copyWith({
    String? id,
    String? householdId,
    String? householdName,
    String? title,
    String? serviceCategory,
    String? description,
    String? city,
    String? area,
    double? latitude,
    double? longitude,
    double? budget,
    DateTime? requiredDate,
    String? status,
    DateTime? createdAt,
  }) {
    return JobPost(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      householdName: householdName ?? this.householdName,
      title: title ?? this.title,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      description: description ?? this.description,
      city: city ?? this.city,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      budget: budget ?? this.budget,
      requiredDate: requiredDate ?? this.requiredDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class JobApplication {
  final String id;
  final String jobPostId;
  final String workerId;
  final String workerName;
  final String workerRole;
  final double workerRating;
  final double proposedRate;
  final String notes;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime appliedAt;

  JobApplication({
    required this.id,
    required this.jobPostId,
    required this.workerId,
    required this.workerName,
    required this.workerRole,
    required this.workerRating,
    required this.proposedRate,
    required this.notes,
    required this.status,
    required this.appliedAt,
  });

  /// Deserializes JobApplication from a Supabase row map.
  /// Handles joined `profiles` for worker name and `worker_profiles` for rating.
  factory JobApplication.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? profileMap;
    if (map['profiles'] is Map<String, dynamic>) {
      profileMap = map['profiles'] as Map<String, dynamic>;
    } else if (map['profiles'] is List &&
        (map['profiles'] as List).isNotEmpty &&
        (map['profiles'] as List).first is Map) {
      profileMap = (map['profiles'] as List).first as Map<String, dynamic>;
    }

    Map<String, dynamic>? workerProfileMap;
    if (map['worker_profiles'] is Map<String, dynamic>) {
      workerProfileMap = map['worker_profiles'] as Map<String, dynamic>;
    } else if (map['worker_profiles'] is List &&
        (map['worker_profiles'] as List).isNotEmpty &&
        (map['worker_profiles'] as List).first is Map) {
      workerProfileMap = (map['worker_profiles'] as List).first as Map<String, dynamic>;
    }

    final String id = map['id']?.toString() ?? '';
    final String jobPostId = map['job_id']?.toString() ??
        map['jobPostId']?.toString() ??
        '';
    final String workerId = map['worker_id']?.toString() ??
        map['workerId']?.toString() ??
        '';
    final String workerName = profileMap?['full_name']?.toString() ??
        map['worker_name']?.toString() ??
        map['workerName']?.toString() ??
        'Worker';
    final String workerRole = map['worker_role']?.toString() ??
        map['workerRole']?.toString() ??
        'Domestic Worker';

    final dynamic rawRating = map['worker_rating'] ?? map['workerRating'] ?? workerProfileMap?['rating'];
    double workerRating = 4.5;
    if (rawRating is num) {
      workerRating = rawRating.toDouble();
    } else if (rawRating is String && rawRating.isNotEmpty) {
      workerRating = double.tryParse(rawRating) ?? 4.5;
    }

    final dynamic rawRate = map['proposed_rate'] ?? map['proposedRate'];
    double proposedRate = 0.0;
    if (rawRate is num) {
      proposedRate = rawRate.toDouble();
    } else if (rawRate is String && rawRate.isNotEmpty) {
      proposedRate = double.tryParse(rawRate) ?? 0.0;
    }

    final String notes = map['notes']?.toString() ?? '';
    final String status = map['status']?.toString() ?? 'pending';

    DateTime appliedAt = DateTime.now();
    final dynamic rawApplied = map['applied_at'] ?? map['appliedAt'];
    if (rawApplied is DateTime) {
      appliedAt = rawApplied;
    } else if (rawApplied is String && rawApplied.isNotEmpty) {
      appliedAt = DateTime.tryParse(rawApplied) ?? DateTime.now();
    }

    return JobApplication(
      id: id,
      jobPostId: jobPostId,
      workerId: workerId,
      workerName: workerName,
      workerRole: workerRole,
      workerRating: workerRating,
      proposedRate: proposedRate,
      notes: notes,
      status: status,
      appliedAt: appliedAt,
    );
  }

  /// Serializes JobApplication to a Map matching Supabase `job_applications` table schema.
  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'job_id': jobPostId,
      'worker_id': workerId,
      'proposed_rate': proposedRate,
      'notes': notes,
      'status': status.toLowerCase(),
    };
    if (id.isNotEmpty &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(id)) {
      data['id'] = id;
    }
    return data;
  }

  JobApplication copyWith({
    String? id,
    String? jobPostId,
    String? workerId,
    String? workerName,
    String? workerRole,
    double? workerRating,
    double? proposedRate,
    String? notes,
    String? status,
    DateTime? appliedAt,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobPostId: jobPostId ?? this.jobPostId,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerRole: workerRole ?? this.workerRole,
      workerRating: workerRating ?? this.workerRating,
      proposedRate: proposedRate ?? this.proposedRate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}

class AIRecommendationResult {
  final WorkerProfile worker;
  final double compositeScore;
  final int matchPercentage;
  final double distanceKm;
  final String xaiBadge;
  final List<String> matchReasons;

  const AIRecommendationResult({
    required this.worker,
    required this.compositeScore,
    required this.matchPercentage,
    required this.distanceKm,
    required this.xaiBadge,
    required this.matchReasons,
  });

  double get score => compositeScore;
}

