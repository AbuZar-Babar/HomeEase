import '../models/worker_profile.dart';

class DummyAuthService {
  // Singleton pattern
  static final DummyAuthService _instance = DummyAuthService._internal();
  factory DummyAuthService() => _instance;

  DummyAuthService._internal() {
    // Seed initial demo users
    _users.addAll([
      AppUser(
        id: 'h_demo_1',
        fullName: 'Babar Khan',
        email: 'household@homeease.com',
        phone: '+923001234567',
        password: 'password123',
        role: 'Household',
        accountStatus: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      AppUser(
        id: 'worker_1', // Rabia Bibi in SampleData.workers
        fullName: 'Rabia Bibi',
        email: 'worker@homeease.com',
        phone: '+923111234567',
        password: 'password123',
        role: 'Worker',
        accountStatus: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ]);
  }

  final List<AppUser> _users = [];
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  /// Validates email/password/role and returns the signed-in [AppUser] if successful,
  /// otherwise returns null.
  AppUser? signIn(String email, String password, String role) {
    try {
      final user = _users.firstWhere(
        (u) =>
            u.email.trim().toLowerCase() == email.trim().toLowerCase() &&
            u.password == password &&
            u.role.toLowerCase() == role.toLowerCase(),
      );
      _currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Registers a new user dynamically in-memory and auto-signs them in.
  AppUser signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) {
    final newUser = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      fullName: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
      accountStatus: 'Active',
      createdAt: DateTime.now(),
    );
    _users.add(newUser);
    _currentUser = newUser;
    return newUser;
  }

  /// Signs out the current user.
  void signOut() {
    _currentUser = null;
  }

  /// Get the seeded demo accounts for quick auto-fill.
  List<AppUser> getDemoAccounts() {
    return _users.where((u) => u.id.startsWith('h_demo') || u.id == 'worker_1').toList();
  }
}
