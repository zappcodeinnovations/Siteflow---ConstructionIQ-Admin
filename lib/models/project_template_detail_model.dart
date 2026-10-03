class TemplateFieldModel {
  final int fieldId;
  final String key;
  final String scope;
  final String label;
  final String fieldType;
  final String placeholder;
  final bool required;
  final int order;
  final String helpText;
  final bool isActive;
  final List<String> options;

  TemplateFieldModel({
    required this.fieldId,
    required this.key,
    required this.scope,
    required this.label,
    required this.fieldType,
    required this.placeholder,
    required this.required,
    required this.order,
    required this.helpText,
    required this.isActive,
    required this.options,
  });

  factory TemplateFieldModel.fromJson(Map<String, dynamic> json) {
    return TemplateFieldModel(
      fieldId: json['field_id'] is int ? json['field_id'] : int.tryParse('${json['field_id']}') ?? 0,
      key: json['key']?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? '',
      placeholder: json['placeholder']?.toString() ?? '',
      required: json['required'] == true,
      order: json['order'] is int ? json['order'] : int.tryParse('${json['order']}') ?? 0,
      helpText: json['help_text']?.toString() ?? '',
      isActive: json['is_active'] != false,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((o) => o is Map ? (o['label']?.toString() ?? o['value']?.toString() ?? '') : o.toString())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }
}

class ProjectTemplateDetailModel {
  final int templateId;
  final String templateName;
  final String? templateSlug;
  final String description;
  final String templateStatus;
  final List<TemplateFieldModel> fields;

  ProjectTemplateDetailModel({
    required this.templateId,
    required this.templateName,
    required this.templateSlug,
    required this.description,
    required this.templateStatus,
    required this.fields,
  });

  factory ProjectTemplateDetailModel.fromJson(Map<String, dynamic> json) {
    return ProjectTemplateDetailModel(
      templateId: json['template_id'] is int ? json['template_id'] : int.tryParse('${json['template_id']}') ?? 0,
      templateName: json['template_name']?.toString() ?? '',
      templateSlug: json['template_slug']?.toString(),
      description: json['description']?.toString() ?? '',
      templateStatus: json['template_status']?.toString() ?? '',
      fields: (json['fields'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TemplateFieldModel.fromJson)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}
