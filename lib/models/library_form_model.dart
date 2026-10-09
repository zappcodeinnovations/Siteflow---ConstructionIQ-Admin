class LibraryFormModel {
  final int id;
  final String name;
  final String? slug;
  final String statusLabel;
  final bool isPublished;
  final int templateCount;
  final String? createdAt;

  LibraryFormModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.statusLabel,
    required this.isPublished,
    required this.templateCount,
    this.createdAt,
  });

  String get formattedCreatedAt {
    if (createdAt == null || createdAt!.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt!);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      // If it's already in dd/mm/yyyy or other format
      return createdAt!;
    }
  }

  factory LibraryFormModel.fromJson(Map<String, dynamic> json) {
    return LibraryFormModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      statusLabel: json['status_label']?.toString() ?? json['status']?.toString() ?? 'Active',
      isPublished: json['is_published'] == true || json['published'] == true,
      templateCount: json['template_count'] is int ? json['template_count'] : int.tryParse('${json['template_count']}') ?? 0,
      createdAt: json['created_at']?.toString() ?? json['created']?.toString() ?? json['created_date']?.toString(),
    );
  }
}
