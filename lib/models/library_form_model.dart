class LibraryFormModel {
  final int id;
  final String name;
  final String? slug;
  final String statusLabel;
  final bool isPublished;
  final int templateCount;

  LibraryFormModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.statusLabel,
    required this.isPublished,
    required this.templateCount,
  });

  factory LibraryFormModel.fromJson(Map<String, dynamic> json) {
    return LibraryFormModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      statusLabel: json['status_label']?.toString() ?? '',
      isPublished: json['is_published'] == true,
      templateCount: json['template_count'] is int ? json['template_count'] : int.tryParse('${json['template_count']}') ?? 0,
    );
  }
}
