class ApiEndpoints {
  static const String baseUrl = 'https://euroside.zappcode.in/api';

  // Auth
  static const String login = '/admin/login/';

  // Dashboard
  static const String dashboard = '/admin/dashboard/';

  // Clients
  static const String clients = '/clients/';

  // Projects
  static const String projects = '/projects/';
  static String projectDetails(int id) => '/projects/$id/';
  static String projectAllInOneDetails(int id) => '/projects/all-in-one/$id/';
  static String projectAssignments(int id) => '/projects/$id/assignments/';

  // Announcements
  static const String announcements = '/admin/announcements/';
  static String announcementDetails(int id) => '/admin/announcements/$id/';

  // Profile
  static const String profile = '/profile/';
}
