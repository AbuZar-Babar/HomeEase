export 'ai_recommendation_result.dart';
export 'app_user.dart';
export 'booking.dart';
export 'dispute.dart';
export 'id_mapping.dart';
export 'job_post.dart';
export 'notification_model.dart';
export 'review.dart';

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
  final List<String> availabilitySlots;
  final String? cnic;

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
    this.availabilitySlots = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    this.cnic,
  });

  /// Formatted NADRA CNIC number adhering to Abbottabad standard format: 13101-XXXXXXX-X.
  String get formattedCnic {
    if (cnic != null && cnic!.isNotEmpty) return cnic!;
    final numDigits = id.replaceAll(RegExp(r'[^0-9]'), '');
    final seed = numDigits.isEmpty ? '1' : numDigits;
    final middle = seed.padRight(7, '4567891').substring(0, 7);
    final last = ((int.tryParse(seed) ?? 1) % 9 + 1).toString();
    return '13101-$middle-$last';
  }

  /// Empty placeholder representation for uninitialized or unselected worker state.
  static const WorkerProfile empty = WorkerProfile(
    id: '',
    name: '',
    role: '',
    rating: 0.0,
    rate: '',
    experience: '',
    availability: '',
    location: '',
    description: '',
    highlight: '',
    reviewsCount: 0,
    availabilitySlots: [],
  );

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
    List<String> availabilitySlots = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final dynamic rawAvail = map['availability'] ?? map['availability_status'] ?? map['availabilityStatus'];
    if (rawAvail is Map) {
      if (rawAvail['status'] != null) {
        availabilityStatus = rawAvail['status'].toString();
      }
      if (rawAvail['slots'] is List) {
        availabilitySlots = (rawAvail['slots'] as List).map((e) => e.toString()).toList();
      }
    } else if (rawAvail is String && rawAvail.isNotEmpty) {
      availabilityStatus = rawAvail;
    }
    if (map['availability_slots'] is List) {
      availabilitySlots = (map['availability_slots'] as List).map((e) => e.toString()).toList();
    } else if (map['availabilitySlots'] is List) {
      availabilitySlots = (map['availabilitySlots'] as List).map((e) => e.toString()).toList();
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
      availabilitySlots: availabilitySlots,
      cnic: map['cnic']?.toString() ?? profileMap?['cnic']?.toString(),
    );
  }

  /// Serializes WorkerProfile to a Map representation matching Supabase schema.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cnic': formattedCnic,
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
        'slots': availabilitySlots,
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
    List<String>? availabilitySlots,
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
    String? cnic,
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
      availabilitySlots: availabilitySlots ?? this.availabilitySlots,
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
      cnic: cnic ?? this.cnic,
    );
  }
}
