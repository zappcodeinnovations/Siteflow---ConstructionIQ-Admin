class User {
  final int id;
  final String? employeeId;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String displayName;
  final String effectiveRole;
  final String? roleLabel;
  final String? initials;
  final String? profileImage;
  final String? profileImageUrl;
  final String? phone;
  final String? team;
  final bool isActive;
  final bool isPasswordSet;
  final String? deviceId;
  final String? fcmToken;
  final bool changePassword;
  final String? joinedAt;
  final String? updatedAt;
  final String? lastLogin;
  final String? companyName;

  User({
    required this.id,
    this.employeeId,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    required this.displayName,
    required this.effectiveRole,
    this.roleLabel,
    this.initials,
    this.profileImage,
    this.profileImageUrl,
    this.phone,
    this.team,
    required this.isActive,
    required this.isPasswordSet,
    this.deviceId,
    this.fcmToken,
    required this.changePassword,
    this.joinedAt,
    this.updatedAt,
    this.lastLogin,
    this.companyName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      employeeId: json['employee_id']?.toString(),
      email: json['email'] ?? '',
      username: json['username'] ?? json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      displayName: json['display_name'] ??
          (json['first_name'] != null && json['last_name'] != null
              ? "${json['first_name']} ${json['last_name']}".trim()
              : (json['email'] ?? '')),
      effectiveRole: json['effective_role'] ?? json['role'] ?? '',
      roleLabel: json['role_label'] ?? json['role']?.toString().toUpperCase(),
      initials: json['initials'],
      profileImage: json['profile_image'],
      profileImageUrl: json['profile_image_url'],
      phone: json['phone']?.toString() ?? json['mobile']?.toString(),
      team: json['team']?.toString(),
      isActive: json['is_active'] ?? true,
      isPasswordSet: json['is_password_set'] ?? false,
      deviceId: json['device_id'],
      fcmToken: json['fcm_token'],
      changePassword: json['change_password'] ?? false,
      joinedAt: json['joined_at'] ?? json['created_at'] ?? json['date_joined'],
      updatedAt: json['updated_at'],
      lastLogin: json['last_login'] ?? json['last_login_at'] ?? json['last_activity'],
      companyName: json['company_name'] ?? json['organization_name'] ?? json['organisation_name'] ?? 'Euroside Construction Limited',
    );
  }
}
