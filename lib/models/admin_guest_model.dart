class AdminGuestProject {
  final int id;
  final String name;
  final String code;

  const AdminGuestProject({
    required this.id,
    required this.name,
    required this.code,
  });

  factory AdminGuestProject.fromJson(Map<String, dynamic> json) {
    return AdminGuestProject(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse('${json['id'] ?? ''}') ?? 0,
      name: '${json['name'] ?? ''}',
      code: '${json['code'] ?? ''}',
    );
  }

  String get label {
    if (name.isEmpty) return code;
    return code.isEmpty ? name : '$name ($code)';
  }
}

class AdminGuest {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String displayName;
  final String phone;
  final bool isActive;
  final String createdAt;
  final String inviteStatus;
  final String sentAt;
  final String expiresAt;
  final List<AdminGuestProject> projects;

  AdminGuest({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.phone,
    required this.isActive,
    required this.createdAt,
    this.inviteStatus = '',
    this.sentAt = '',
    this.expiresAt = '',
    this.projects = const [],
  });

  factory AdminGuest.fromJson(Map<String, dynamic> json) {
    final firstName = '${json['first_name'] ?? ''}';
    final lastName = '${json['last_name'] ?? ''}';
    final email = '${json['email'] ?? ''}';
    final displayName = '${json['display_name'] ?? ''}'.trim();
    final rawProjects = json['projects'];

    return AdminGuest(
      id: json['id'] ?? 0,
      email: email,
      username: '${json['username'] ?? ''}',
      firstName: firstName,
      lastName: lastName,
      displayName: displayName.isNotEmpty
          ? displayName
          : '$firstName $lastName'.trim().isNotEmpty
          ? '$firstName $lastName'.trim()
          : email,
      phone: '${json['phone'] ?? ''}',
      isActive: json['is_active'] ?? false,
      createdAt: '${json['created_at'] ?? json['sent_at'] ?? ''}',
      inviteStatus: '${json['status'] ?? ''}',
      sentAt: '${json['sent_at'] ?? ''}',
      expiresAt: '${json['expires_at'] ?? ''}',
      projects: rawProjects is List
          ? rawProjects
                .whereType<Map>()
                .map(
                  (project) => AdminGuestProject.fromJson(
                    project.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
    );
  }

  bool get isPending => inviteStatus.isNotEmpty;

  int get projectCount => projects.length;

  String get projectSummary {
    if (projects.isEmpty) return 'No projects';
    if (projects.length == 1) return projects.first.label;
    return '${projects.length} Projects';
  }
}

class AdminGuestResponse {
  final bool status;
  final String message;
  final List<AdminGuest> data;
  final int count;
  final int page;
  final int pageSize;
  final int totalPages;
  final int activeCount;
  final int invitedCount;

  AdminGuestResponse({
    required this.status,
    required this.message,
    required this.data,
    this.count = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 0,
    this.activeCount = 0,
    this.invitedCount = 0,
  });

  factory AdminGuestResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'];
    List<AdminGuest> guests = [];
    if (dataList is List) {
      guests = dataList.map((i) => AdminGuest.fromJson(i)).toList();
    } else if (dataList is Map<String, dynamic>) {
      if (dataList.containsKey('results') && dataList['results'] is List) {
        guests = (dataList['results'] as List)
            .map((i) => AdminGuest.fromJson(i))
            .toList();
      } else {
        guests.add(AdminGuest.fromJson(dataList));
      }
    }

    return AdminGuestResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: guests,
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalPages: json['total_pages'] ?? 0,
      activeCount: _toInt(json['active']),
      invitedCount: _toInt(json['invited']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }
}
