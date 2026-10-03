class LibraryTemplateModel {
  final int id;
  final String name;
  final String? slug;
  final String description;
  final String statusLabel;
  final int fieldCount;

  LibraryTemplateModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.statusLabel,
    required this.fieldCount,
  });

  factory LibraryTemplateModel.fromJson(Map<String, dynamic> json) {
    return LibraryTemplateModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      fieldCount: json['field_count'] is int ? json['field_count'] : int.tryParse('${json['field_count']}') ?? 0,
    );
  }
}
