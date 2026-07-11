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
  });
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
    required this.createdAt,
  });
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
