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
