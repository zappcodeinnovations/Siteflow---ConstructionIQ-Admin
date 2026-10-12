class JobFormOptionModel {
  final int id;
  final String name;

  JobFormOptionModel({required this.id, required this.name});

  factory JobFormOptionModel.fromJson(Map<String, dynamic> json) {
    return JobFormOptionModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class JobOperativeOptionModel {
  final String id;
  final String name;
  final String employeeId;

  JobOperativeOptionModel({required this.id, required this.name, this.employeeId = ''});

  factory JobOperativeOptionModel.fromJson(Map<String, dynamic> json) {
    return JobOperativeOptionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
    );
  }
}

class JobCreateSetupModel {
  final String jobNoDisplay;
  final List<JobFormOptionModel> forms;
  final List<String> siteContacts;
  final List<JobOperativeOptionModel> operatives;

  JobCreateSetupModel({
    required this.jobNoDisplay,
    required this.forms,
    required this.siteContacts,
    this.operatives = const [],
  });

  factory JobCreateSetupModel.fromJson(Map<String, dynamic> json) {
    return JobCreateSetupModel(
      jobNoDisplay: json['job_no']?['display']?.toString() ?? '',
      forms: (json['forms'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(JobFormOptionModel.fromJson)
          .toList(),
      siteContacts: (json['site_contacts'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      operatives: (json['operatives'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(JobOperativeOptionModel.fromJson)
          .toList(),
    );
  }
}
