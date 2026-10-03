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

class JobCreateSetupModel {
  final String jobNoDisplay;
  final List<JobFormOptionModel> forms;
  final List<String> siteContacts;

  JobCreateSetupModel({
    required this.jobNoDisplay,
    required this.forms,
    required this.siteContacts,
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
    );
  }
}
