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
  static String projectHseDocuments(int projectId) => '/projects/$projectId/hse-documents/';
  static String myApprovals({int? projectId}) =>
      projectId == null ? '/my-approvals/' : '/my-approvals/?project_id=$projectId';
  static String projectJobCreate(int projectId) => '/operative/projects/$projectId/jobs/create/';
  static String projectApprovalStages(int projectId) => '/projects/$projectId/approval-stages/';
  static String projectApprovalStageDetail(int projectId, int stageId) => '/projects/$projectId/approval-stages/$stageId/';
  static String projectApprovalStageReorder(int projectId) => '/projects/$projectId/approval-stages/reorder/';
  static String projectFormApprovals(int projectId) => '/projects/$projectId/form-approvals/';

  static String projectSpecifications(int projectId) => '/projects/$projectId/specifications/';
  static String projectSpecificationDetail(int projectId, int specId) => '/projects/$projectId/specifications/$specId/';
  static String projectSpecificationAttributes(int projectId, int specId) => '/projects/$projectId/specifications/$specId/attributes/';
  static String projectSpecificationFiles(int projectId, int specId) => '/projects/$projectId/specifications/$specId/files/';
  static String projectSpecificationFileDetail(int projectId, int specId, int fileId) => '/projects/$projectId/specifications/$specId/files/$fileId/';
  static String projectSpecificationMaterials(int projectId, int specId) => '/projects/$projectId/specifications/$specId/materials/';
  static String projectSpecificationMaterialDetail(int projectId, int specId, int materialId) => '/projects/$projectId/specifications/$specId/materials/$materialId/';
  static String projectSpecificationPriceItems(int projectId, int specId) => '/projects/$projectId/specifications/$specId/price-items/';
  static String projectSpecificationPriceItemDetail(int projectId, int specId, int itemId) => '/projects/$projectId/specifications/$specId/price-items/$itemId/';
  static String projectSpecificationAttributeDefinitions(int projectId) => '/projects/$projectId/specification-attribute-definitions/';
  static String projectSpecificationAttributeDefinitionDetail(int projectId, int definitionId) => '/projects/$projectId/specification-attribute-definitions/$definitionId/';

  static const String adminMaterials = '/admin/materials/';
  static const String adminMaterialsBulk = '/admin/materials/bulk/';
  static String adminMaterialDetail(int materialId) => '/admin/materials/$materialId/';
  static String adminMaterialRateSets(int materialId) => '/admin/materials/$materialId/rate-sets/';
  static String adminMaterialRateSetDetail(int materialId, int rateSetId) => '/admin/materials/$materialId/rate-sets/$rateSetId/';
  static String adminMaterialAttachments(int materialId) => '/admin/materials/$materialId/attachments/';
  static String adminMaterialAttachmentDetail(int materialId, int attachmentId) => '/admin/materials/$materialId/attachments/$attachmentId/';

  // Library (global catalog)
  static const String libraryForms = '/library/forms/';
  static const String libraryMaterials = '/library/materials/';
  static const String libraryTemplates = '/library/templates/';

  // Tasks (global, admin/manager)
  static const String adminTasks = '/admin/tasks/';
  static String adminTaskDelete(int taskId) => '/admin/tasks/$taskId/';

  // Work Types (admin/manager master data, under Library on web)
  static const String adminWorkTypes = '/admin/work-types/';
  static String adminWorkTypeDetail(int workTypeId) => '/admin/work-types/$workTypeId/';

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
