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
  final List<Map<String, dynamic>> qualifications;

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
    this.qualifications = const [],
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
      qualifications: (json['qualifications'] as List? ?? [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(),
    );
  }
}

class AdminMemberResponse {
  final bool status;
  final String message;
  final List<AdminMember> data;
  final int? totalCount;
  final int? assignedCount;
  final int? invitedCount;

  AdminMemberResponse({
    required this.status,
    required this.message,
    required this.data,
    this.totalCount,
    this.assignedCount,
    this.invitedCount,
  });

  factory AdminMemberResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'];
    List<AdminMember> members = [];
    int? totalCount = json['total'] ?? json['count'] ?? json['total_count'] ?? json['total_members'];
    int? assigned = json['assigned'] ?? json['assigned_count'] ?? json['assigned_seats'];
    int? invited = json['invited'] ?? json['invited_count'] ?? json['invited_seats'];

    if (dataList is List) {
      members = dataList.map((i) => AdminMember.fromJson(i)).toList();
    } else if (dataList is Map<String, dynamic>) {
      totalCount ??= dataList['total'] ?? dataList['count'] ?? dataList['total_count'] ?? dataList['total_members'];
      assigned ??= dataList['assigned'] ?? dataList['assigned_count'] ?? dataList['assigned_seats'];
      invited ??= dataList['invited'] ?? dataList['invited_count'] ?? dataList['invited_seats'];

      if (dataList.containsKey('results') && dataList['results'] is List) {
        members = (dataList['results'] as List).map((i) => AdminMember.fromJson(i)).toList();
      } else if (dataList.containsKey('members') && dataList['members'] is List) {
        members = (dataList['members'] as List).map((i) => AdminMember.fromJson(i)).toList();
      } else {
        members.add(AdminMember.fromJson(dataList));
      }
    }
    return AdminMemberResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: members,
      totalCount: totalCount,
      assignedCount: assigned,
      invitedCount: invited,
    );
  }
}
