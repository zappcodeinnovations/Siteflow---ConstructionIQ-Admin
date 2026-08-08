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
  });

  factory AdminGuest.fromJson(Map<String, dynamic> json) {
    return AdminGuest(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      displayName: json['display_name'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
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

  AdminGuestResponse({
    required this.status,
    required this.message,
    required this.data,
    this.count = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 0,
  });

  factory AdminGuestResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'];
    List<AdminGuest> guests = [];
    if (dataList is List) {
      guests = dataList.map((i) => AdminGuest.fromJson(i)).toList();
    } else if (dataList is Map<String, dynamic>) {
      if (dataList.containsKey('results') && dataList['results'] is List) {
        guests = (dataList['results'] as List).map((i) => AdminGuest.fromJson(i)).toList();
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
    );
  }
}
