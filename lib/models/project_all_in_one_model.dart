import 'project_model.dart';

class ProjectAllInOneModel {
  final Project? project;
  final List<dynamic> tasks;
  final List<dynamic> jobSheets;
  final List<dynamic> approvals;
  final List<dynamic> hse;
  final List<dynamic> drawings;
  final List<dynamic> locations;
  final List<dynamic> specifications;
  final List<dynamic> docsFolders;
  final List<dynamic> docsFiles;
  final Map<String, dynamic>? projectSetup;

  ProjectAllInOneModel({
    this.project,
    this.tasks = const [],
    this.jobSheets = const [],
    this.approvals = const [],
    this.hse = const [],
    this.drawings = const [],
    this.locations = const [],
    this.specifications = const [],
    this.docsFolders = const [],
    this.docsFiles = const [],
    this.projectSetup,
  });

  factory ProjectAllInOneModel.fromJson(Map<String, dynamic> json) {
    return ProjectAllInOneModel(
      project: json['project'] != null ? Project.fromJson(json['project']) : null,
      tasks: json['tasks'] ?? [],
      jobSheets: json['job_sheets'] ?? [],
      approvals: json['approvals'] ?? [],
      hse: json['hse'] ?? [],
      drawings: json['drawings'] ?? [],
      locations: json['locations'] ?? [],
      specifications: json['specifications'] ?? [],
      docsFolders: json['docs_folders'] ?? [],
      docsFiles: json['docs_files'] ?? [],
      projectSetup: json['project_setup'],
    );
  }
}
