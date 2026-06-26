class AdminMember {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String displayName;
  final String role;
  final String roleDisplayName;
  final String phone;
  final String employeeId;
  final bool isActive;
  final int? team;
  final String teamName;
  final bool onetraceProEnabled;
  final String createdAt;

  AdminMember({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.role,
    required this.roleDisplayName,
    required this.phone,
    required this.employeeId,
    required this.isActive,
    this.team,
    required this.teamName,
    required this.onetraceProEnabled,
    required this.createdAt,
  });

  factory AdminMember.fromJson(Map<String, dynamic> json) {
    return AdminMember(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      displayName: json['display_name'] ?? '',
      role: json['role'] ?? '',
      roleDisplayName: json['role_display_name'] ?? '',
      phone: json['phone'] ?? '',
      employeeId: json['employee_id'] ?? '',
      isActive: json['is_active'] ?? false,
      team: json['team'],
      teamName: json['team_name'] ?? '-',
      onetraceProEnabled: json['onetrace_pro_enabled'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class AdminMemberResponse {
  final bool status;
  final String message;
  final List<AdminMember> data;

  AdminMemberResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AdminMemberResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'];
    List<AdminMember> members = [];
    if (dataList is List) {
      members = dataList.map((i) => AdminMember.fromJson(i)).toList();
    } else if (dataList is Map<String, dynamic>) {
      // Sometimes APIs might return pagination structure: {"results": [...]}
      // We handle simple array here based on provided examples
      if (dataList.containsKey('results') && dataList['results'] is List) {
        members = (dataList['results'] as List).map((i) => AdminMember.fromJson(i)).toList();
      } else {
        // If it's a single item
        members.add(AdminMember.fromJson(dataList));
      }
    }
    return AdminMemberResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: members,
    );
  }
}
