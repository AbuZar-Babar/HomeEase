import 'package:flutter/material.dart';

import '../services/supabase_auth_service.dart';
import '../services/worker_repository.dart';
import '../services/job_repository.dart';
import '../services/booking_repository.dart';
import '../services/dispute_repository.dart';
import '../services/localization_service.dart';
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
import '../screens/worker_map_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../services/audit_log_service.dart';
import '../widgets/app_scaffold.dart';

class HomeEaseFlow extends StatefulWidget {
  const HomeEaseFlow({super.key});

  @override
  State<HomeEaseFlow> createState() => _HomeEaseFlowState();
}

class _HomeEaseFlowState extends State<HomeEaseFlow> {
  AppStage _stage = AppStage.splash;
  WorkerProfile _selectedWorker = WorkerProfile.empty;
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

  final List<AppStage> _stageHistory = [];

  @override
  void initState() {
    super.initState();
    _loadLiveWorkers();
    _loadLiveJobs();
    _loadLiveBookings();
    _restoreSession();
  }

  bool _isRootStage() {
    return _stage == AppStage.splash ||
        _stage == AppStage.onboarding ||
        _stage == AppStage.signIn ||
        (_currentUserRole.toLowerCase() == 'admin'
            ? _stage == AppStage.adminDashboard
            : (_currentUserRole.toLowerCase() == 'worker'
                ? _stage == AppStage.workerDashboard
                : _stage == AppStage.homeSearch));
  }

  void _goTo(AppStage stage, {bool clearHistory = false}) {
    if (clearHistory) {
      _stageHistory.clear();
    } else if (_stage != stage) {
      _stageHistory.add(_stage);
    }
    setState(() {
      _stage = stage;
    });
  }

  void _goBack() {
    if (_stageHistory.isNotEmpty) {
      final prev = _stageHistory.removeLast();
      setState(() {
        _stage = prev;
      });
    } else {
      final roleLower = _currentUserRole.toLowerCase();
      final root = roleLower == 'admin'
          ? AppStage.adminDashboard
          : (roleLower == 'worker' ? AppStage.workerDashboard : AppStage.homeSearch);
      if (_stage != root) {
        setState(() {
          _stage = root;
        });
      }
    }
  }

  void _selectWorker(WorkerProfile worker, AppStage stage) {
    if (_stage != stage) {
      _stageHistory.add(_stage);
    }
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
    if (_currentUserRole.toLowerCase() == 'admin' || _stage == AppStage.adminDashboard) {
      return null;
    }
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
          _stage == AppStage.bookingsHistory;
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
      if (mounted) {
        setState(() {
          _liveWorkers = workers;
          if (workers.isNotEmpty) {
            if (_selectedWorker.id.isEmpty || _selectedWorker.id == 'worker_1') {
              _selectedWorker = workers.first;
            }
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
      final apps = await JobRepository().fetchAllApplications();
      if (mounted) {
        setState(() {
          _jobPosts.clear();
          _jobPosts.addAll(jobs);
          _jobApplications.clear();
          _jobApplications.addAll(apps);
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
        await _loadLiveBookings();
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isRootStage() && _stageHistory.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: AnimatedSwitcher(
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
            if (user != null && user.role.toLowerCase() == 'admin') {
              setState(() {
                _currentUserRole = 'Admin';
              });
              _goTo(AppStage.adminDashboard);
            } else if (user != null && user.role.toLowerCase() == 'worker') {
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
          onAdminSignIn: () {
            setState(() {
              _currentUserRole = 'Admin';
            });
            AuditLogService().logEvent(
              actionType: 'auth',
              title: 'Admin Session Authenticated',
              description: 'System Administrator logged in to governance terminal.',
              actor: 'Admin (admin@homeease.com)',
              severity: 'info',
            );
            _goTo(AppStage.adminDashboard);
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
          featuredWorkers: _liveWorkers,
          onToggleService: _toggleService,
          onOpenWorkers: () => _goTo(AppStage.workerList),
          onOpenWorker: (worker) => _selectWorker(worker, AppStage.workerDetail),
          onOpenWorkerMap: () => _goTo(AppStage.workerMap),
          onLogout: () {
            SupabaseAuthService().signOut();
            _goTo(AppStage.signIn);
          },
          onOpenBookings: () => _goTo(AppStage.bookingsHistory),
          onOpenNotifications: () => _goTo(AppStage.notifications),
          unreadNotificationsCount: _getUnreadNotificationsCount(),
          onOpenPostJob: () => _goTo(AppStage.postJob),
          onOpenProfile: () => _goTo(AppStage.profile),
          onLanguageChanged: () => setState(() {}),
          bottomNavigationBar: _buildBottomNav(),
        );

      case AppStage.workerMap:
        return WorkerMapScreen(
          workers: _liveWorkers,
          onSelectWorker: (w) => _selectWorker(w, AppStage.workerDetail),
          onBack: _goBack,
        );
        
      case AppStage.workerList:
        return WorkerListScreen(
          workers: _liveWorkers,
          onBack: _goBack,
          onSelectWorker: (worker) => _selectWorker(worker, AppStage.workerDetail),
        );
        
      case AppStage.workerDetail:
        return WorkerDetailScreen(
          worker: _selectedWorker,
          onBack: _goBack,
          onBookNow: () => _goTo(AppStage.bookingRequest),
        );
        
      case AppStage.bookingRequest:
        return BookingRequestScreen(
          worker: _selectedWorker,
          onBack: _goBack,
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
          workers: _liveWorkers,
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
        final allWorkers = _liveWorkers;
        final worker = allWorkers.firstWhere(
          (w) => IdMapping.matchesWorker(w.id, _selectedBooking.workerId),
          orElse: () => allWorkers.isNotEmpty ? allWorkers.first : WorkerProfile.empty,
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
          onPaymentCompleted: (result) async {
            try {
              final updated = await BookingRepository().completeBookingPayment(
                bookingId: _selectedBooking.id,
                paymentMethod: result.mode.dbValue,
                txId: result.txId,
              );
              if (!mounted) return;
              setState(() {
                final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                if (index != -1) {
                  _bookings[index] = updated;
                }
                _selectedBooking = updated;
              });
            } catch (_) {
              if (mounted) {
                setState(() {
                  final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                  final updated = _selectedBooking.copyWith(
                    status: 'Completed',
                    paymentStatus: 'confirmed',
                    paymentMethod: result.mode.dbValue,
                  );
                  if (index != -1) {
                    _bookings[index] = updated;
                  }
                  _selectedBooking = updated;
                });
              }
            }
            if (mounted) {
              setState(() {
                _notifications.add(
                  NotificationModel(
                    id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
                    userId: 'h_1',
                    title: 'Payment Successful',
                    message: 'Your payment (${result.mode.displayName}) TxID ${result.txId} has been confirmed.',
                    type: 'Payment',
                    isRead: false,
                    createdAt: DateTime.now(),
                  ),
                );
              });
            }
          },
          onVerifyArrival: () async {
            try {
              final updated = await BookingRepository().updateBookingStatus(_selectedBooking.id, 'In Progress');
              if (!mounted) return;
              setState(() {
                final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                if (index != -1) {
                  _bookings[index] = updated;
                }
                _selectedBooking = updated;
              });
            } catch (_) {
              if (mounted) {
                setState(() {
                  final index = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, _selectedBooking.id));
                  final updated = _selectedBooking.copyWith(status: 'In Progress');
                  if (index != -1) {
                    _bookings[index] = updated;
                  }
                  _selectedBooking = updated;
                });
              }
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
          onBack: _goBack,
          onSubmit: (category, desc, proof) async {
            try {
              final createdDispute = await DisputeRepository().createDispute(
                bookingId: _selectedBooking.id,
                complainantId: _selectedBooking.employerId,
                respondentId: _selectedBooking.workerId,
                category: category,
                description: desc,
                evidencePath: proof,
              );

              if (mounted) {
                setState(() {
                  _disputes.removeWhere((d) => d.id == createdDispute.id);
                  _disputes.insert(0, createdDispute);
                  _notifications.add(
                    NotificationModel(
                      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
                      userId: _selectedBooking.employerId,
                      title: 'Dispute Filed',
                      message: LocalizationService.isUrdu
                          ? 'تنازعہ برائے "$category" کامیابی کے ساتھ "open" حیثیت میں درج کر لیا گیا۔'
                          : 'A dispute for "$category" has been recorded under status "open" and submitted for administrative arbitration.',
                      type: 'Dispute',
                      isRead: false,
                      createdAt: DateTime.now(),
                    ),
                  );
                });
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LocalizationService.isUrdu
                          ? 'تنازعہ کامیابی سے درج کر لیا گیا ہے (حیثیت: کھلا)۔ بکنگ کی تاریخ محفوظ ہے اور ایڈمن اس کا جائزہ لے گا۔'
                          : 'Dispute recorded under status "open" and submitted for administrative arbitration while booking history remains untouched.',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      LocalizationService.isUrdu
                          ? 'تنازعہ درج کرنے میں خرابی پیش آگئی۔'
                          : 'Failed to record dispute: $e',
                    ),
                  ),
                );
              }
            }

            _goTo(AppStage.bookingsHistory);
          },
        );
        
      case AppStage.ratingReview:
        final allWorkers = _liveWorkers;
        final worker = allWorkers.firstWhere(
          (w) => IdMapping.matchesWorker(w.id, _selectedBooking.workerId),
          orElse: () => allWorkers.isNotEmpty ? allWorkers.first : WorkerProfile.empty,
        );
        return RatingReviewScreen(
          booking: _selectedBooking,
          worker: worker,
          onBack: _goBack,
          onSubmit: (rating, comment) async {
            final updatedWorkers = await WorkerRepository().fetchWorkers();
            if (mounted) {
              setState(() {
                _liveWorkers = updatedWorkers;
              });
            }
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
          onSave: (status, slots) async {
            final workerId = SupabaseAuthService().currentUser?.id ?? '00000000-0000-0000-0000-000000000010';
            await WorkerRepository().updateWorkerAvailability(
              workerId: workerId,
              status: status,
              slots: slots,
            );
            final updatedWorkers = await WorkerRepository().fetchWorkers();
            if (mounted) {
              setState(() {
                _availabilityStatus = status;
                _availabilitySlots = slots;
                _liveWorkers = updatedWorkers;
              });
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    LocalizationService.isUrdu
                        ? 'دستیابی کی ترتیبات کامیابی کے ساتھ محفوظ ہو گئیں۔'
                        : 'Availability settings updated successfully.',
                  ),
                ),
              );
            }
            _goTo(AppStage.workerDashboard);
          },
        );
        
      case AppStage.notifications:
        return NotificationsScreen(
          notifications: _notifications,
          onBack: _goBack,
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
          applications: _jobApplications,
          onAcceptApplication: (app) async {
            try {
              // 1. Mark application accepted and job assigned via JobRepository().acceptApplication
              await JobRepository().acceptApplication(app.id, jobId: app.jobPostId);

              // Locate target job
              final targetJob = _jobPosts.firstWhere(
                (j) => IdMapping.matchesJob(j.id, app.jobPostId),
                orElse: () => JobPost(
                  id: app.jobPostId,
                  householdId: SupabaseAuthService().currentUser?.id ?? '00000000-0000-0000-0000-000000000001',
                  householdName: 'Household Employer',
                  title: 'Domestic Task',
                  serviceCategory: 'Cleaner',
                  description: 'Task agreed via accepted proposal',
                  city: 'Abbottabad',
                  area: 'Mandian',
                  latitude: 34.1983,
                  longitude: 73.2425,
                  budget: app.proposedRate > 0 ? app.proposedRate : 2500,
                  requiredDate: DateTime.now().add(const Duration(days: 1)),
                  status: 'assigned',
                  createdAt: DateTime.now(),
                ),
              );

              // 2. Synthesize confirmed booking via BookingRepository with agreed rate
              final confirmedBooking = await BookingRepository().synthesizeConfirmedBooking(
                job: targetJob,
                application: app,
              );

              // 3. Mutate _jobApplications, _jobPosts, _bookings, set _selectedBooking = confirmedBooking
              if (!mounted) return;
              setState(() {
                final appIdx = _jobApplications.indexWhere((a) => a.id == app.id);
                if (appIdx != -1) {
                  _jobApplications[appIdx] = app.copyWith(status: 'accepted');
                }
                for (var i = 0; i < _jobApplications.length; i++) {
                  if (_jobApplications[i].id != app.id && IdMapping.matchesJob(_jobApplications[i].jobPostId, app.jobPostId)) {
                    _jobApplications[i] = _jobApplications[i].copyWith(status: 'rejected');
                  }
                }

                final jobIdx = _jobPosts.indexWhere((j) => IdMapping.matchesJob(j.id, app.jobPostId));
                if (jobIdx != -1) {
                  _jobPosts[jobIdx] = _jobPosts[jobIdx].copyWith(status: 'assigned');
                }

                final bIdx = _bookings.indexWhere((b) => IdMapping.matchesBooking(b.id, confirmedBooking.id));
                if (bIdx != -1) {
                  _bookings[bIdx] = confirmedBooking;
                } else {
                  _bookings.insert(0, confirmedBooking);
                }

                _selectedBooking = confirmedBooking;
              });

              // 4. Immediately transition to AppStage.serviceAgreement
              _goTo(AppStage.serviceAgreement);
            } catch (e) {
              debugPrint('Error accepting application: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error accepting bid: $e')),
                );
              }
            }
          },
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
        final allWorkers = _liveWorkers;
        final currentWorkerId = SupabaseAuthService().currentUser?.id ?? '00000000-0000-0000-0000-000000000010';
        final activeWorker = allWorkers.firstWhere(
          (w) => IdMapping.matchesWorker(w.id, currentWorkerId),
          orElse: () => allWorkers.isNotEmpty ? allWorkers.first : WorkerProfile.empty,
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
          onBack: _goBack,
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

      case AppStage.adminDashboard:
        return AdminDashboardScreen(
          onLogout: () async {
            await SupabaseAuthService().signOut();
            AuditLogService().logEvent(
              actionType: 'auth',
              title: 'Admin Session Terminated',
              description: 'System Administrator logged out safely.',
              actor: 'Admin (admin@homeease.com)',
              severity: 'info',
            );
            if (!mounted) return;
            setState(() {
              _currentUserRole = 'Household';
            });
            _goTo(AppStage.signIn, clearHistory: true);
          },
          onLanguageChanged: () => setState(() {}),
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
  workerMap,
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
  adminDashboard,
}
