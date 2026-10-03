class ApiEndpoints {
  static const String baseUrl = 'https://euroside.zappcode.in/api';

  // Auth
  static const String login = '/admin/login/';
  static const String refresh = '/admin/token/refresh/'; // Please verify if this matches your backend

  // Dashboard
  static const String dashboard = '/admin/dashboard/';

  // Clients
  static const String clients = '/clients/';

  // Projects
  static const String projects = '/projects/';
  static String projectDetails(int id) => '/projects/$id/';
  static String projectAllInOneDetails(int id) => '/projects/all-in-one/$id/';
  static String projectAssignments(int id) => '/projects/$id/assignments/';
  static String projectIncidents(int projectId) => '/projects/$projectId/incidents/';
  static String projectSnags(int projectId) => '/projects/$projectId/snags/';
  static String projectInspections(int projectId) => '/projects/$projectId/inspections/';
  static String inspectionComplete(int inspectionId) => '/inspections/$inspectionId/complete/';
  static String projectTemplateDetail(int projectId) => '/projects/$projectId/template/';
  static String projectMaterials(int projectId) => '/projects/$projectId/materials/';
  static String myApprovals({int? projectId}) =>
      projectId == null ? '/my-approvals/' : '/my-approvals/?project_id=$projectId';
  static String projectJobCreate(int projectId) => '/operative/projects/$projectId/jobs/create/';

  // Announcements
  static const String announcements = '/admin/announcements/';
  static String announcementDetails(int id) => '/admin/announcements/$id/';

  // Profile
  static const String profile = '/profile/';

  // Job Sheets / Daily Reports
  static const String jobSheets = '/job-sheets/';

  // Weekly Diary
  static const String weeklyDiary = '/weekly-diary/';

  // Manager Diary
  static const String managerDiary = '/manager-diary/';
  static const String managerDiaryForms = '/manager-diary/forms/';
  static String userFormHtml(int formId) => '/userform/$formId/html/';
}
