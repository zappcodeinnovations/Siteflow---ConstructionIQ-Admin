class JobSheet {
  final int id;
  final String sheetNo;
  final String status;
  final String statusLabel;
  final String jobNo;
  final String jobReference;
  final String projectName;
  final String clientName;
  final String operative;
  final String operativeCode;
  final String form;
  final String location;
  final String comments;
  final String materialCost;
  final String charge;
  final String globalDetailApiUrl;
  final String created;
  final String submitted;
  final String lastUpdated;

  JobSheet({
    required this.id,
    required this.sheetNo,
    required this.status,
    required this.statusLabel,
    required this.jobNo,
    required this.jobReference,
    required this.projectName,
    required this.clientName,
    required this.operative,
    required this.operativeCode,
    required this.form,
    required this.location,
    required this.comments,
    required this.materialCost,
    required this.charge,
    required this.globalDetailApiUrl,
    required this.created,
    required this.submitted,
    required this.lastUpdated,
  });

  factory JobSheet.fromJson(Map<String, dynamic> json) {
    return JobSheet(
      id: json['id'] ?? 0,
      sheetNo: json['sheet_no'] ?? '',
      status: json['status'] ?? 'Unknown',
      statusLabel: json['status_label'] ?? 'Unknown',
      jobNo: json['job_no'] ?? '',
      jobReference: json['job_reference'] ?? '',
      projectName: json['project_name'] ?? '',
      clientName: json['client_name'] ?? '',
      operative: json['operative'] ?? '',
      operativeCode: json['operative_code'] ?? '',
      form: json['form'] ?? '',
      location: json['location'] ?? '',
      comments: json['comments'] ?? '',
      materialCost: json['material_cost']?.toString() ?? '',
      charge: json['charge']?.toString() ?? '',
      globalDetailApiUrl: json['global_detail_api_url'] ?? '',
      created: json['created'] ?? '',
      submitted: json['submitted'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

class JobSheetResponse {
  final bool status;
  final String message;
  final int count;
  final int page;
  final int pageSize;
  final int totalPages;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> filterOptions;
  final List<JobSheet> data;

  JobSheetResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.filters,
    required this.filterOptions,
    required this.data,
  });

  factory JobSheetResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    List<JobSheet> sheets = dataList.map((i) => JobSheet.fromJson(i)).toList();

    return JobSheetResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalPages: json['total_pages'] ?? 0,
      filters: json['filters'] ?? {},
      filterOptions: json['filter_options'] ?? {},
      data: sheets,
    );
  }
}
