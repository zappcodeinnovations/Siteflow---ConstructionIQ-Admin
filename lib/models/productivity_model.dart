class ProductivitySummary {
  final int activeProjects;
  final int activeMembers;
  final int jobSheets;
  final double operativeTotal;
  final double materialCostTotal;
  final double chargeTotal;

  ProductivitySummary({
    required this.activeProjects,
    required this.activeMembers,
    required this.jobSheets,
    required this.operativeTotal,
    required this.materialCostTotal,
    required this.chargeTotal,
  });

  factory ProductivitySummary.fromJson(Map<String, dynamic> json) {
    return ProductivitySummary(
      activeProjects: json['active_projects'] ?? 0,
      activeMembers: json['active_members'] ?? 0,
      jobSheets: json['job_sheets'] ?? 0,
      operativeTotal: (json['operative_total'] ?? 0.0).toDouble(),
      materialCostTotal: (json['material_cost_total'] ?? 0.0).toDouble(),
      chargeTotal: (json['charge_total'] ?? 0.0).toDouble(),
    );
  }
}

class MemberProductivity {
  final int id;
  final String name;
  final String initials;
  final String team;
  final int jobSheets;
  final double operative;
  final double materialCost;
  final double charge;

  MemberProductivity({
    required this.id,
    required this.name,
    required this.initials,
    required this.team,
    required this.jobSheets,
    required this.operative,
    required this.materialCost,
    required this.charge,
  });

  factory MemberProductivity.fromJson(Map<String, dynamic> json) {
    return MemberProductivity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      initials: json['initials'] ?? '',
      team: json['team'] ?? '',
      jobSheets: json['job_sheets'] ?? 0,
      operative: (json['operative'] ?? 0.0).toDouble(),
      materialCost: (json['material_cost'] ?? 0.0).toDouble(),
      charge: (json['charge'] ?? 0.0).toDouble(),
    );
  }
}

class TeamProductivity {
  final String team;
  final int members;
  final int jobSheets;
  final double operative;
  final double materialCost;
  final double charge;

  TeamProductivity({
    required this.team,
    required this.members,
    required this.jobSheets,
    required this.operative,
    required this.materialCost,
    required this.charge,
  });

  factory TeamProductivity.fromJson(Map<String, dynamic> json) {
    return TeamProductivity(
      team: json['team'] ?? '',
      members: json['members'] ?? 0,
      jobSheets: json['job_sheets'] ?? 0,
      operative: (json['operative'] ?? 0.0).toDouble(),
      materialCost: (json['material_cost'] ?? 0.0).toDouble(),
      charge: (json['charge'] ?? 0.0).toDouble(),
    );
  }
}

class ProjectProductivity {
  final int id;
  final String name;
  final String client;
  final int members;
  final int jobSheets;
  final double operative;
  final double materialCost;
  final double charge;

  ProjectProductivity({
    required this.id,
    required this.name,
    required this.client,
    required this.members,
    required this.jobSheets,
    required this.operative,
    required this.materialCost,
    required this.charge,
  });

  factory ProjectProductivity.fromJson(Map<String, dynamic> json) {
    return ProjectProductivity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      client: json['client'] ?? '',
      members: json['members'] ?? 0,
      jobSheets: json['job_sheets'] ?? 0,
      operative: (json['operative'] ?? 0.0).toDouble(),
      materialCost: (json['material_cost'] ?? 0.0).toDouble(),
      charge: (json['charge'] ?? 0.0).toDouble(),
    );
  }
}

class ProductivityResponse {
  final bool status;
  final String message;
  final String view;
  final ProductivitySummary? summary;
  final Map<String, dynamic> filterOptions;
  final Map<String, dynamic> filters;
  final List<MemberProductivity> byMember;
  final List<TeamProductivity> byTeam;
  final List<ProjectProductivity> byProject;

  ProductivityResponse({
    required this.status,
    required this.message,
    required this.view,
    this.summary,
    required this.filterOptions,
    required this.filters,
    required this.byMember,
    required this.byTeam,
    required this.byProject,
  });

  factory ProductivityResponse.fromJson(Map<String, dynamic> json) {
    var memberList = json['by_member'] as List? ?? [];
    var teamList = json['by_team'] as List? ?? [];
    var projectList = json['by_project'] as List? ?? [];

    return ProductivityResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      view: json['view'] ?? 'member',
      summary: json['summary'] != null ? ProductivitySummary.fromJson(json['summary']) : null,
      filterOptions: json['filter_options'] ?? {},
      filters: json['filters'] ?? {},
      byMember: memberList.map((i) => MemberProductivity.fromJson(i)).toList(),
      byTeam: teamList.map((i) => TeamProductivity.fromJson(i)).toList(),
      byProject: projectList.map((i) => ProjectProductivity.fromJson(i)).toList(),
    );
  }
}
