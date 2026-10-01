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
import '../screens/profile_screen.dart';
import '../screens/worker_job_feed_screen.dart';
import '../screens/worker_list_screen.dart';
import '../widgets/app_scaffold.dart';

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

  int _getHouseholdTabIndex(AppStage stage) {
    switch (stage) {
      case AppStage.homeSearch:
        return 0;
      case AppStage.postJob:
        return 1;
      case AppStage.bookingsHistory:
        return 2;
      case AppStage.profile:
        return 3;
      default:
        return 0;
    }
  }

  void _onHouseholdTabTapped(int index) {
    switch (index) {
      case 0:
        _goTo(AppStage.homeSearch);
        break;
      case 1:
        _goTo(AppStage.postJob);
        break;
      case 2:
        _goTo(AppStage.bookingsHistory);
        break;
      case 3:
        _goTo(AppStage.profile);
        break;
    }
  }

  int _getWorkerTabIndex(AppStage stage) {
    switch (stage) {
      case AppStage.workerDashboard:
        return 0;
      case AppStage.workerJobFeed:
        return 1;
      case AppStage.bookingsHistory:
        return 2;
      case AppStage.workerAvailability:
        return 3;
      default:
        return 0;
    }
  }

  void _onWorkerTabTapped(int index) {
    switch (index) {
      case 0:
        _goTo(AppStage.workerDashboard);
        break;
      case 1:
        _goTo(AppStage.workerJobFeed);
        break;
      case 2:
        _goTo(AppStage.bookingsHistory);
        break;
      case 3:
        _goTo(AppStage.workerAvailability);
        break;
    }
  }

  Widget? _buildBottomNav() {
    final isWorker = _currentUserRole.toLowerCase() == 'worker';
    if (isWorker) {
      final isRootWorkerStage = _stage == AppStage.workerDashboard ||
          _stage == AppStage.workerJobFeed ||
          _stage == AppStage.bookingsHistory ||
          _stage == AppStage.workerAvailability;
      if (!isRootWorkerStage) return null;
      return HomeEaseBottomNav(
        currentIndex: _getWorkerTabIndex(_stage),
        onTap: _onWorkerTabTapped,
        isWorker: true,
        unreadCount: _getUnreadNotificationsCount(),
      );
    } else {
      final isRootHouseholdStage = _stage == AppStage.homeSearch ||
          _stage == AppStage.postJob ||
          _stage == AppStage.bookingsHistory ||
          _stage == AppStage.profile;
      if (!isRootHouseholdStage) return null;
      return HomeEaseBottomNav(
        currentIndex: _getHouseholdTabIndex(_stage),
        onTap: _onHouseholdTabTapped,
        isWorker: false,
        unreadCount: _getUnreadNotificationsCount(),
      );
    }
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
      final isWorker = (user?.role.toLowerCase() == 'worker') || (_currentUserRole == 'Worker');
      final effectiveId = user?.id ??
          (isWorker
              ? '00000000-0000-0000-0000-000000000010'
              : '00000000-0000-0000-0000-000000000001');
      final bookings = isWorker
          ? await BookingRepository().fetchBookingsForWorker(effectiveId)
          : await BookingRepository().fetchBookingsForHousehold(effectiveId);

      if (mounted) {
        setState(() {
          if (user != null || bookings.isNotEmpty) {
            _bookings.clear();
            _bookings.addAll(bookings);
          }
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
        await _loadLiveBookings();
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_stage),
        child: _buildStageContent(context),
      ),
    );
  }

  Widget _buildStageContent(BuildContext context) {
    switch (_stage) {
      case AppStage.splash:
        return SplashScreen(onAnimationComplete: () {
          final auth = SupabaseAuthService();
          if (auth.isAuthenticated) {
            final user = auth.currentUser;
            if (user != null && user.role.toLowerCase() == 'worker') {
              setState(() {
                _currentUserRole = 'Worker';
              });
              _goTo(AppStage.workerDashboard);
            } else {
              setState(() {
                _currentUserRole = 'Household';
              });
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
            _loadLiveBookings();
            _goTo(AppStage.homeSearch);
          },
          onWorkerSignIn: () {
            setState(() {
              _currentUserRole = 'Worker';
            });
            _loadLiveBookings();
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
              _loadLiveBookings();
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
          bottomNavigationBar: _buildBottomNav(),
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
          onSubmit: (createdBooking) {
            setState(() {
              _bookings.insert(0, createdBooking);

              // Add notification
              _notifications.add(
                NotificationModel(
                  id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
                  userId: createdBooking.householdId,
                  title: 'Booking Request Sent',
                  message: 'Booking request sent to ${_selectedWorker.name}. Waiting for acceptance.',
                  type: 'Booking',
                  isRead: false,
                  createdAt: DateTime.now(),
                ),
              );
            });
            _goTo(AppStage.bookingsHistory);
          },
        );
        
      case AppStage.bookingsHistory:
        final user = SupabaseAuthService().currentUser;
        final isWorker = (_currentUserRole.toLowerCase() == 'worker') || (user?.role.toLowerCase() == 'worker');
        final currentId = user?.id ??
            (isWorker
                ? '00000000-0000-0000-0000-000000000010'
                : '00000000-0000-0000-0000-000000000001');
        final relevantBookings = _bookings.where((b) {
          return isWorker
              ? IdMapping.matchesWorker(b.workerId, currentId)
              : IdMapping.matchesHousehold(b.householdId, currentId);
        }).toList();
        return BookingsHistoryScreen(
          bookings: relevantBookings,
          workers: _liveWorkers.isNotEmpty ? _liveWorkers : SampleData.workers,
          onBack: null,
          roleBadge: isWorker ? 'Worker' : 'Household',
          onToggleLanguage: () => setState(() {}),
          onOpenNotifications: () => _goTo(AppStage.notifications),
          unreadNotificationsCount: _getUnreadNotificationsCount(),
          onLogout: () async {
            await SupabaseAuthService().signOut();
            if (!mounted) return;
            setState(() {
              _bookings.clear();
              _currentUserRole = 'Household';
            });
            _goTo(AppStage.signIn);
          },
          bottomNavigationBar: _buildBottomNav(),
          onRefresh: _loadLiveBookings,
          onStatusChanged: (updated) {
            setState(() {
              final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, updated.id));
              if (index != -1) {
                _bookings[index] = updated;
              } else {
                _bookings.insert(0, updated);
              }
            });
          },
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
        final allWorkers = _liveWorkers.isNotEmpty ? _liveWorkers : SampleData.workers;
        final worker = allWorkers.firstWhere(
          (w) => IdMapping.matchesWorker(w.id, _selectedBooking.workerId),
          orElse: () => allWorkers.first,
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
          onSubmitReceipt: (txId, receiptPath) async {
            try {
              final updated = await BookingRepository().updateBookingStatus(_selectedBooking.id, 'Completed');
              if (!mounted) return;
              setState(() {
                final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                if (index != -1) {
                  _bookings[index] = updated;
                  _selectedBooking = updated;
                }
              });
            } catch (_) {
              if (mounted) {
                setState(() {
                  final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                  if (index != -1) {
                    final updated = _selectedBooking.copyWith(status: 'Completed');
                    _bookings[index] = updated;
                    _selectedBooking = updated;
                  }
                });
              }
            }
            if (mounted) {
              setState(() {
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment receipt submitted and confirmed!')),
                );
                _goTo(AppStage.bookingsHistory);
              }
            }
          },
          onConfirmPayment: () async {
            try {
              final updated = await BookingRepository().updateBookingStatus(_selectedBooking.id, 'Completed');
              if (!mounted) return;
              setState(() {
                final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                if (index != -1) {
                  _bookings[index] = updated;
                  _selectedBooking = updated;
                }
              });
            } catch (_) {
              if (mounted) {
                setState(() {
                  final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                  if (index != -1) {
                    final updated = _selectedBooking.copyWith(status: 'Completed');
                    _bookings[index] = updated;
                    _selectedBooking = updated;
                  }
                });
              }
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment confirmed! Job completed.')),
              );
              _goTo(AppStage.workerDashboard);
            }
          },
          onRejectPayment: () async {
            try {
              final updated = await BookingRepository().updateBookingStatus(_selectedBooking.id, 'Disputed');
              if (!mounted) return;
              setState(() {
                final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                if (index != -1) {
                  _bookings[index] = updated;
                  _selectedBooking = updated;
                }
              });
            } catch (_) {
              if (mounted) {
                setState(() {
                  final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                  if (index != -1) {
                    final updated = _selectedBooking.copyWith(status: 'Disputed');
                    _bookings[index] = updated;
                    _selectedBooking = updated;
                  }
                });
              }
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt rejected. Dispute opened.')),
              );
              _goTo(AppStage.workerDashboard);
            }
          },
          onRaiseDispute: () {
            _goTo(AppStage.disputeReport);
          },
        );
        
      case AppStage.disputeReport:
        return DisputeReportScreen(
          booking: _selectedBooking,
          onBack: () => _goTo(AppStage.bookingsHistory),
          onSubmit: (category, desc, proof) async {
            try {
              final updated = await BookingRepository().updateBookingStatus(_selectedBooking.id, 'Disputed');
              if (mounted) {
                setState(() {
                  final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                  if (index != -1) {
                    _bookings[index] = updated;
                    _selectedBooking = updated;
                  }
                });
              }
            } catch (_) {
              if (mounted) {
                setState(() {
                  final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                  if (index != -1) {
                    final updated = _selectedBooking.copyWith(status: 'Disputed');
                    _bookings[index] = updated;
                    _selectedBooking = updated;
                  }
                });
              }
            }

            if (!mounted) return;
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

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dispute filed successfully. Admin will review.')),
              );
            }
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
          (w) => IdMapping.matchesWorker(w.id, _selectedBooking.workerId),
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
        final currentWorkerId = SupabaseAuthService().currentUser?.id ?? '00000000-0000-0000-0000-000000000010';
        final workerBookings = _bookings.where((b) => IdMapping.matchesWorker(b.workerId, currentWorkerId)).toList();
        return WorkerDashboardScreen(
          bookings: workerBookings,
          verificationStatus: _workerVerificationStatus,
          workerName: SupabaseAuthService().currentUser?.fullName,
          onRefresh: _loadLiveBookings,
          onAcceptBooking: (booking) {
            setState(() {
              final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
              if (index != -1) {
                _bookings[index] = booking;
              } else {
                _bookings.insert(0, booking);
              }
            });
          },
          onRejectBooking: (booking) {
            setState(() {
              final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
              if (index != -1) {
                _bookings[index] = booking;
              } else {
                _bookings.insert(0, booking);
              }
            });
          },
          onCompleteBooking: (booking) {
            setState(() {
              final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, booking.id));
              if (index != -1) {
                _bookings[index] = booking;
              } else {
                _bookings.insert(0, booking);
              }
            });
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
          bottomNavigationBar: _buildBottomNav(),
          onLogout: () async {
            await SupabaseAuthService().signOut();
            if (!mounted) return;
            setState(() {
              _bookings.clear();
              _currentUserRole = 'Household';
            });
            _goTo(AppStage.signIn);
          },
        );
        
      case AppStage.workerAvailability:
        return WorkerAvailabilityScreen(
          initialStatus: _availabilityStatus,
          initialSlots: _availabilitySlots,
          onBack: null,
          roleBadge: 'Worker',
          onToggleLanguage: () => setState(() {}),
          onOpenNotifications: () => _goTo(AppStage.notifications),
          unreadNotificationsCount: _getUnreadNotificationsCount(),
          onLogout: () async {
            await SupabaseAuthService().signOut();
            if (!mounted) return;
            setState(() {
              _bookings.clear();
              _currentUserRole = 'Household';
            });
            _goTo(AppStage.signIn);
          },
          bottomNavigationBar: _buildBottomNav(),
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
          existingJobs: _jobPosts,
          onJobPosted: (newJob) {
            setState(() {
              _jobPosts.insert(0, newJob);
            });
            _goTo(AppStage.homeSearch);
          },
          onBack: null,
          bottomNavigationBar: _buildBottomNav(),
        );

      case AppStage.workerJobFeed:
        final allWorkers = _liveWorkers.isNotEmpty ? _liveWorkers : SampleData.workers;
        final currentWorkerId = SupabaseAuthService().currentUser?.id ?? '00000000-0000-0000-0000-000000000010';
        final activeWorker = allWorkers.firstWhere(
          (w) => IdMapping.matchesWorker(w.id, currentWorkerId),
          orElse: () => allWorkers.first,
        );
        return WorkerJobFeedScreen(
          jobPosts: _jobPosts,
          currentWorker: activeWorker,
          onApply: (application) {
            setState(() {
              _jobApplications.insert(0, application);
            });
          },
          onBack: null,
          bottomNavigationBar: _buildBottomNav(),
        );

      case AppStage.profile:
        final user = SupabaseAuthService().currentUser;
        final currentId = user?.id ?? '00000000-0000-0000-0000-000000000001';
        final userBookings = _bookings.where((b) => IdMapping.matchesHousehold(b.householdId, currentId)).toList();
        return ProfileScreen(
          userRole: _currentUserRole,
          totalBookings: userBookings.length,
          totalPostedGigs: _jobPosts.length,
          onLanguageChanged: () => setState(() {}),
          bottomNavigationBar: _buildBottomNav(),
          onLogout: () async {
            await SupabaseAuthService().signOut();
            if (!mounted) return;
            setState(() {
              _bookings.clear();
              _currentUserRole = 'Household';
            });
            _goTo(AppStage.signIn);
          },
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
  profile,
}
