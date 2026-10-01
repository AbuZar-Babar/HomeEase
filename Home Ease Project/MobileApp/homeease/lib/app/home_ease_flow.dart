import 'package:flutter/material.dart';

import '../services/supabase_auth_service.dart';
import '../services/worker_repository.dart';
import '../services/job_repository.dart';
import '../services/booking_repository.dart';
import '../data/sample_data.dart';
import '../models/worker_profile.dart';
import '../screens/booking_request_screen.dart';
import '../screens/bookings_history_screen.dart';
import '../screens/dispute_report_screen.dart';
import '../screens/home_search_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/post_job_screen.dart';
import '../screens/rating_review_screen.dart';
import '../screens/service_agreement_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/worker_availability_screen.dart';
import '../screens/worker_dashboard_screen.dart';
import '../screens/worker_detail_screen.dart';
import '../screens/worker_job_feed_screen.dart';
import '../screens/worker_list_screen.dart';
import '../services/localization_service.dart';

class HomeEaseFlow extends StatefulWidget {
  const HomeEaseFlow({super.key});

  @override
  State<HomeEaseFlow> createState() => _HomeEaseFlowState();
}

class _HomeEaseFlowState extends State<HomeEaseFlow> {
  AppStage _stage = AppStage.splash;
  WorkerProfile _selectedWorker = SampleData.workers.first;
  final Set<String> _selectedServices = {'Cleaner'};
  
  // Role & Session State
  String _currentUserRole = 'Household';
  String _workerVerificationStatus = 'PendingVerification'; // 'PendingVerification', 'Verified', 'RejectedVerification'
  String _selectedRoleForSignUp = 'Household';
  
  // Live Workers & Data State
  List<WorkerProfile> _liveWorkers = [];
  
  // Dynamic Lists for Local Mock State
  final List<Booking> _bookings = [];
  final List<NotificationModel> _notifications = [];
  final List<Dispute> _disputes = [];
  final List<JobPost> _jobPosts = [];
  final List<JobApplication> _jobApplications = [];
  late Booking _selectedBooking;

  // Initial Worker Availability Settings
  String _availabilityStatus = 'Available today';
  List<String> _availabilitySlots = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  @override
  void initState() {
    super.initState();
    _loadLiveWorkers();
    _loadLiveJobs();
    _loadLiveBookings();
    _restoreSession();
    // Pre-populate history with completed and accepted bookings for local demo
    _bookings.addAll([
      Booking(
        id: 'booking_1',
        householdId: 'h_1',
        workerId: 'worker_3', // Sana Gul
        serviceCategoryId: 'Cleaner',
        bookingDate: DateTime.now().subtract(const Duration(days: 2)),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        address: 'House 14, Lane 2, Mandian, Abbottabad',
        notes: 'Deep kitchen cleaning requested.',
        agreedAmount: 2200,
        status: 'Completed',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Booking(
        id: 'booking_2',
        householdId: 'h_1',
        workerId: 'worker_1', // Rabia Bibi
        serviceCategoryId: 'Cook',
        bookingDate: DateTime.now().add(const Duration(days: 2)),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        address: 'House 14, Lane 2, Mandian, Abbottabad',
        notes: 'Prepare traditional dinner meals.',
        agreedAmount: 3000,
        status: 'Accepted',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // Pre-populate notifications
    _notifications.addAll([
      NotificationModel(
        id: 'notif_1',
        userId: 'any',
        title: 'Welcome to HomeEase',
        message: 'Your account has been set up successfully. Find verified help nearby.',
        type: 'General',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: 'notif_2',
        userId: 'any',
        title: 'Booking Confirmed',
        message: 'Rabia Bibi accepted your booking request for cooking.',
        type: 'Booking',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      NotificationModel(
        id: 'notif_3',
        userId: 'any',
        title: 'Verification In-Review',
        message: 'Your worker profile details are currently being reviewed by admin.',
        type: 'Verification',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ]);

    // Pre-populate open job posts for Abbottabad bidirectional marketplace
    _jobPosts.addAll(SampleData.initialJobPosts);
  }

  void _goTo(AppStage stage) {
    setState(() {
      _stage = stage;
    });
  }

  void _selectWorker(WorkerProfile worker, AppStage stage) {
    setState(() {
      _selectedWorker = worker;
      _stage = stage;
    });
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  int _getUnreadNotificationsCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  Future<void> _loadLiveWorkers() async {
    try {
      final workers = await WorkerRepository().fetchWorkers();
      if (mounted && workers.isNotEmpty) {
        setState(() {
          _liveWorkers = workers;
          if (_selectedWorker.id.isEmpty || _selectedWorker.id == 'worker_1') {
            _selectedWorker = workers.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading live workers: $e');
    }
  }

  Future<void> _loadLiveJobs() async {
    try {
      final jobs = await JobRepository().fetchOpenJobs();
      if (mounted && jobs.isNotEmpty) {
        setState(() {
          _jobPosts.clear();
          _jobPosts.addAll(jobs);
        });
      }
    } catch (e) {
      debugPrint('Error loading live jobs: $e');
    }
  }

  Future<void> _loadLiveBookings() async {
    try {
      final user = SupabaseAuthService().currentUser;
      final effectiveId = user?.id ?? '00000000-0000-0000-0000-000000000001';
      final isWorker = user?.role.toLowerCase() == 'worker';
      final bookings = isWorker
          ? await BookingRepository().fetchBookingsForWorker(effectiveId)
          : await BookingRepository().fetchBookingsForHousehold(effectiveId);

      if (mounted && bookings.isNotEmpty) {
        setState(() {
          _bookings.clear();
          _bookings.addAll(bookings);
        });
      }
    } catch (e) {
      debugPrint('Error loading live bookings: $e');
    }
  }

  Future<void> _restoreSession() async {
    try {
      final user = await SupabaseAuthService().restoreSession();
      if (mounted && user != null) {
        setState(() {
          _currentUserRole = user.role;
        });
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case AppStage.splash:
        return SplashScreen(onAnimationComplete: () {
          final auth = SupabaseAuthService();
          if (auth.isAuthenticated) {
            final user = auth.currentUser;
            if (user != null && user.role.toLowerCase() == 'worker') {
              _goTo(AppStage.workerDashboard);
            } else {
              _goTo(AppStage.homeSearch);
            }
          } else {
            _goTo(AppStage.onboarding);
          }
        });
        
      case AppStage.onboarding:
        return OnboardingScreen(onFinished: () => _goTo(AppStage.signIn));
        
      case AppStage.signIn:
        return SignInScreen(
          onSignIn: () {
            setState(() {
              _currentUserRole = 'Household';
            });
            _goTo(AppStage.homeSearch);
          },
          onWorkerSignIn: () {
            setState(() {
              _currentUserRole = 'Worker';
            });
            _goTo(AppStage.workerDashboard);
          },
          onCreateAccount: (role) {
            setState(() {
              _selectedRoleForSignUp = role;
            });
            _goTo(AppStage.signUp);
          },
        );
        
      case AppStage.signUp:
        return SignUpScreen(
          initialRole: _selectedRoleForSignUp,
          onCreateAccount: (role, data) async {
            try {
              await SupabaseAuthService().signUp(
                name: data['name'],
                email: data['email'],
                phone: data['phone'],
                password: data['password'],
                role: role,
                tradeData: role == 'Worker' ? data : null,
              );
              if (!mounted) return;
              setState(() {
                _currentUserRole = role;
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account created as $role successfully.')),
                );
              }
              if (role == 'Household') {
                _goTo(AppStage.homeSearch);
              } else {
                setState(() {
                  _workerVerificationStatus = 'PendingVerification';
                });
                _goTo(AppStage.workerDashboard);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating account: $e')),
                );
              }
            }
          },
          onBack: () => _goTo(AppStage.signIn),
          onSignIn: () => _goTo(AppStage.signIn),
        );
        
      case AppStage.homeSearch:
        return HomeSearchScreen(
          services: SampleData.serviceFilters,
          selectedServices: _selectedServices,
          featuredWorkers: _liveWorkers.isNotEmpty ? _liveWorkers : SampleData.workers,
          onToggleService: _toggleService,
          onOpenWorkers: () => _goTo(AppStage.workerList),
          onOpenWorker: (worker) => _selectWorker(worker, AppStage.workerDetail),
          onLogout: () {
            SupabaseAuthService().signOut();
            _goTo(AppStage.signIn);
          },
          onOpenBookings: () => _goTo(AppStage.bookingsHistory),
          onOpenNotifications: () => _goTo(AppStage.notifications),
          unreadNotificationsCount: _getUnreadNotificationsCount(),
          onOpenPostJob: () => _goTo(AppStage.postJob),
          onLanguageChanged: () => setState(() {}),
        );
        
      case AppStage.workerList:
        return WorkerListScreen(
          workers: _liveWorkers.isNotEmpty ? _liveWorkers : SampleData.workers,
          onBack: () => _goTo(AppStage.homeSearch),
          onSelectWorker: (worker) => _selectWorker(worker, AppStage.workerDetail),
        );
        
      case AppStage.workerDetail:
        return WorkerDetailScreen(
          worker: _selectedWorker,
          onBack: () => _goTo(AppStage.workerList),
          onBookNow: () => _goTo(AppStage.bookingRequest),
        );
        
      case AppStage.bookingRequest:
        return BookingRequestScreen(
          worker: _selectedWorker,
          onBack: () => _goTo(AppStage.workerDetail),
          onSubmit: (bookingData) async {
            final auth = SupabaseAuthService();
            final householdId = auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000001';
            final newBooking = Booking(
              id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
              householdId: householdId,
              workerId: _selectedWorker.id,
              serviceCategoryId: _selectedWorker.role,
              bookingDate: bookingData['date'],
              startTime: bookingData['startTime'],
              endTime: bookingData['endTime'],
              address: bookingData['address'],
              notes: bookingData['notes'],
              agreedAmount: (bookingData['agreedAmount'] as num?)?.toDouble() ?? 2500.0,
              status: 'Pending',
              createdAt: DateTime.now(),
            );

            try {
              final created = await BookingRepository().createBooking(newBooking);
              if (!mounted) return;
              setState(() {
                _bookings.insert(0, created);

                // Add notification
                _notifications.add(
                  NotificationModel(
                    id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
                    userId: householdId,
                    title: 'Booking Request Sent',
                    message: 'Booking request sent to ${_selectedWorker.name}. Waiting for acceptance.',
                    type: 'Booking',
                    isRead: false,
                    createdAt: DateTime.now(),
                  ),
                );
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking request submitted successfully.')),
                );
                _goTo(AppStage.homeSearch);
              }
            } on BookingConflictException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red.shade700,
                    content: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.message)),
                      ],
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booking error: $e')),
                );
              }
            }
          },
        );
        
      case AppStage.bookingsHistory:
        return BookingsHistoryScreen(
          bookings: _bookings,
          workers: _liveWorkers.isNotEmpty ? _liveWorkers : SampleData.workers,
          onBack: () => _goTo(AppStage.homeSearch),
          onSelectBooking: (booking) {
            setState(() {
              _selectedBooking = booking;
            });
            _goTo(AppStage.serviceAgreement);
          },
          onRateBooking: (booking) {
            setState(() {
              _selectedBooking = booking;
            });
            _goTo(AppStage.ratingReview);
          },
          onRaiseDispute: (booking) {
            setState(() {
              _selectedBooking = booking;
            });
            _goTo(AppStage.disputeReport);
          },
        );
        
      case AppStage.serviceAgreement:
        final worker = SampleData.workers.firstWhere(
          (w) => w.id == _selectedBooking.workerId,
          orElse: () => SampleData.workers.first,
        );
        return ServiceAgreementScreen(
          booking: _selectedBooking,
          worker: worker,
          isWorker: _currentUserRole == 'Worker',
          onBack: () {
            if (_currentUserRole == 'Household') {
              _goTo(AppStage.bookingsHistory);
            } else {
              _goTo(AppStage.workerDashboard);
            }
          },
          onSubmitReceipt: (txId, receiptPath) {
            // Update booking status for local demo
            setState(() {
              final index = _bookings.indexWhere((b) => b.id == _selectedBooking.id);
              if (index != -1) {
                // Update booking status in the list
                final updated = Booking(
                  id: _selectedBooking.id,
                  householdId: _selectedBooking.householdId,
                  workerId: _selectedBooking.workerId,
                  serviceCategoryId: _selectedBooking.serviceCategoryId,
                  bookingDate: _selectedBooking.bookingDate,
                  startTime: _selectedBooking.startTime,
                  endTime: _selectedBooking.endTime,
                  address: _selectedBooking.address,
                  notes: _selectedBooking.notes,
                  agreedAmount: _selectedBooking.agreedAmount,
                  status: 'Completed', // auto-complete for local rapid flow
                  createdAt: _selectedBooking.createdAt,
                );
                _bookings[index] = updated;
                _selectedBooking = updated;
              }

              _notifications.add(
                NotificationModel(
                  id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
                  userId: 'h_1',
                  title: 'Payment Submitted',
                  message: 'Your payment reference $txId has been uploaded and auto-completed.',
                  type: 'Payment',
                  isRead: false,
                  createdAt: DateTime.now(),
                ),
              );
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment receipt submitted and confirmed!')),
            );
            _goTo(AppStage.bookingsHistory);
          },
          onConfirmPayment: () {
            setState(() {
              final index = _bookings.indexWhere((b) => b.id == _selectedBooking.id);
              if (index != -1) {
                final updated = Booking(
                  id: _selectedBooking.id,
                  householdId: _selectedBooking.householdId,
                  workerId: _selectedBooking.workerId,
                  serviceCategoryId: _selectedBooking.serviceCategoryId,
                  bookingDate: _selectedBooking.bookingDate,
                  startTime: _selectedBooking.startTime,
                  endTime: _selectedBooking.endTime,
                  address: _selectedBooking.address,
                  notes: _selectedBooking.notes,
                  agreedAmount: _selectedBooking.agreedAmount,
                  status: 'Completed',
                  createdAt: _selectedBooking.createdAt,
                );
                _bookings[index] = updated;
                _selectedBooking = updated;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment confirmed! Job completed.')),
            );
            _goTo(AppStage.workerDashboard);
          },
          onRejectPayment: () {
            setState(() {
              final index = _bookings.indexWhere((b) => b.id == _selectedBooking.id);
              if (index != -1) {
                final updated = Booking(
                  id: _selectedBooking.id,
                  householdId: _selectedBooking.householdId,
                  workerId: _selectedBooking.workerId,
                  serviceCategoryId: _selectedBooking.serviceCategoryId,
                  bookingDate: _selectedBooking.bookingDate,
                  startTime: _selectedBooking.startTime,
                  endTime: _selectedBooking.endTime,
                  address: _selectedBooking.address,
                  notes: _selectedBooking.notes,
                  agreedAmount: _selectedBooking.agreedAmount,
                  status: 'Disputed',
                  createdAt: _selectedBooking.createdAt,
                );
                _bookings[index] = updated;
                _selectedBooking = updated;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt rejected. Dispute opened.')),
            );
            _goTo(AppStage.workerDashboard);
          },
          onRaiseDispute: () {
            _goTo(AppStage.disputeReport);
          },
        );
        
      case AppStage.disputeReport:
        return DisputeReportScreen(
          booking: _selectedBooking,
          onBack: () => _goTo(AppStage.bookingsHistory),
          onSubmit: (category, desc, proof) {
            setState(() {
              // Add dispute
              _disputes.add(
                Dispute(
                  id: 'dispute_${DateTime.now().millisecondsSinceEpoch}',
                  bookingId: _selectedBooking.id,
                  paymentRecordId: 'payment_1',
                  raisedBy: _currentUserRole,
                  againstUserId: 'other',
                  category: category,
                  description: desc,
                  evidenceURL: proof,
                  status: 'OpenDispute',
                  adminRemarks: 'Pending review by admin panel.',
                  createdAt: DateTime.now(),
                ),
              );

              // Update booking status
              final index = _bookings.indexWhere((b) => b.id == _selectedBooking.id);
              if (index != -1) {
                final updated = Booking(
                  id: _selectedBooking.id,
                  householdId: _selectedBooking.householdId,
                  workerId: _selectedBooking.workerId,
                  serviceCategoryId: _selectedBooking.serviceCategoryId,
                  bookingDate: _selectedBooking.bookingDate,
                  startTime: _selectedBooking.startTime,
                  endTime: _selectedBooking.endTime,
                  address: _selectedBooking.address,
                  notes: _selectedBooking.notes,
                  agreedAmount: _selectedBooking.agreedAmount,
                  status: 'Disputed',
                  createdAt: _selectedBooking.createdAt,
                );
                _bookings[index] = updated;
              }

              // Add notification
              _notifications.add(
                NotificationModel(
                  id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
                  userId: 'any',
                  title: 'Dispute Filed',
                  message: 'A dispute for "$category" has been filed and sent to the admin dashboard.',
                  type: 'Dispute',
                  isRead: false,
                  createdAt: DateTime.now(),
                ),
              );
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dispute filed successfully. Admin will review.')),
            );
            if (_currentUserRole == 'Household') {
              _goTo(AppStage.bookingsHistory);
            } else {
              _goTo(AppStage.workerDashboard);
            }
          },
        );
        
      case AppStage.ratingReview:
        final allWorkers = _liveWorkers.isNotEmpty ? _liveWorkers : SampleData.workers;
        final worker = allWorkers.firstWhere(
          (w) => w.id == _selectedBooking.workerId,
          orElse: () => allWorkers.first,
        );
        return RatingReviewScreen(
          booking: _selectedBooking,
          worker: worker,
          onBack: () => _goTo(AppStage.bookingsHistory),
          onSubmit: (rating, comment) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Feedback submitted: $rating stars. Thank you!')),
            );
            _goTo(AppStage.bookingsHistory);
          },
        );
        
      case AppStage.workerDashboard:
        // Filter bookings belonging to current logged in worker (or worker_1 as default)
        final currentWorkerId = SupabaseAuthService().currentUser?.id ?? '00000000-0000-0000-0000-000000000010';
        final workerBookings = _bookings.where((b) => b.workerId == currentWorkerId || b.workerId == 'worker_1').toList();
        return WorkerDashboardScreen(
          bookings: workerBookings,
          verificationStatus: _workerVerificationStatus,
          workerName: SupabaseAuthService().currentUser?.fullName,
          onAcceptBooking: (booking) async {
            try {
              final updated = await BookingRepository().updateBookingStatus(booking.id, 'Accepted');
              if (!mounted) return;
              setState(() {
                final index = _bookings.indexWhere((b) => b.id == booking.id);
                if (index != -1) {
                  _bookings[index] = updated;
                }
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job accepted! Agreement generated.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error accepting job: $e')),
                );
              }
            }
          },
          onRejectBooking: (booking) async {
            try {
              final updated = await BookingRepository().updateBookingStatus(booking.id, 'Rejected');
              if (!mounted) return;
              setState(() {
                final index = _bookings.indexWhere((b) => b.id == booking.id);
                if (index != -1) {
                  _bookings[index] = updated;
                }
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job request declined.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error declining job: $e')),
                );
              }
            }
          },
          onManageAvailability: () => _goTo(AppStage.workerAvailability),
          onOpenNotifications: () => _goTo(AppStage.notifications),
          unreadNotificationsCount: _getUnreadNotificationsCount(),
          onSelectBooking: (booking) {
            setState(() {
              _selectedBooking = booking;
            });
            _goTo(AppStage.serviceAgreement);
          },
          onBrowseAvailableJobs: () => _goTo(AppStage.workerJobFeed),
          onLanguageChanged: () => setState(() {}),
          onLogout: () {
            SupabaseAuthService().signOut();
            _goTo(AppStage.signIn);
          },
        );
        
      case AppStage.workerAvailability:
        return WorkerAvailabilityScreen(
          initialStatus: _availabilityStatus,
          initialSlots: _availabilitySlots,
          onBack: () => _goTo(AppStage.workerDashboard),
          onSave: (status, slots) {
            setState(() {
              _availabilityStatus = status;
              _availabilitySlots = slots;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Availability settings updated successfully.')),
            );
            _goTo(AppStage.workerDashboard);
          },
        );
        
      case AppStage.notifications:
        return NotificationsScreen(
          notifications: _notifications,
          onBack: () {
            if (_currentUserRole == 'Household') {
              _goTo(AppStage.homeSearch);
            } else {
              _goTo(AppStage.workerDashboard);
            }
          },
          onClearAll: () {
            setState(() {
              _notifications.clear();
            });
          },
          onMarkAsRead: (notif) {
            setState(() {
              final index = _notifications.indexWhere((n) => n.id == notif.id);
              if (index != -1) {
                _notifications[index] = NotificationModel(
                  id: notif.id,
                  userId: notif.userId,
                  title: notif.title,
                  message: notif.message,
                  type: notif.type,
                  isRead: true,
                  createdAt: notif.createdAt,
                );
              }
            });
            
            // If it's a verification notification, let's trigger self-verification as user requested
            if (notif.type == 'Verification' && _workerVerificationStatus == 'PendingVerification') {
              setState(() {
                _workerVerificationStatus = 'Verified';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Self-verification: Profile verified by admin simulator.')),
              );
            }
          },
        );

      case AppStage.postJob:
        return PostJobScreen(
          onJobPosted: (newJob) async {
            try {
              final created = await JobRepository().createJob(newJob);
              if (!mounted) return;
              setState(() {
                _jobPosts.insert(0, created);
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(LocalizationService.tr('postSuccess'))),
                );
                _goTo(AppStage.homeSearch);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error posting job: $e')),
                );
              }
            }
          },
          onBack: () => _goTo(AppStage.homeSearch),
        );

      case AppStage.workerJobFeed:
        final allWorkers = _liveWorkers.isNotEmpty ? _liveWorkers : SampleData.workers;
        final currentWorkerId = SupabaseAuthService().currentUser?.id ?? '00000000-0000-0000-0000-000000000010';
        final activeWorker = allWorkers.firstWhere(
          (w) => w.id == currentWorkerId || w.id == 'worker_1',
          orElse: () => allWorkers.first,
        );
        return WorkerJobFeedScreen(
          jobPosts: _jobPosts,
          currentWorker: activeWorker,
          onApply: (application) async {
            try {
              final created = await JobRepository().applyForJob(application);
              if (!mounted) return;
              setState(() {
                _jobApplications.insert(0, created);
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(LocalizationService.tr('applySuccess'))),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e')),
                );
              }
            }
          },
          onBack: () => _goTo(AppStage.workerDashboard),
        );
    }
  }
}

enum AppStage {
  splash,
  onboarding,
  signIn,
  signUp,
  homeSearch,
  workerList,
  workerDetail,
  bookingRequest,
  bookingsHistory,
  serviceAgreement,
  disputeReport,
  ratingReview,
  workerDashboard,
  workerAvailability,
  notifications,
  postJob,
  workerJobFeed,
}
