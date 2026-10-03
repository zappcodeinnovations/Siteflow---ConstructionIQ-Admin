class MaterialRateTierModel {
  final String tierType;
  final String tierTypeLabel;
  final String? thresholdValue;
  final String flatAmount;
  final String perUnitAmount;

  MaterialRateTierModel({
    required this.tierType,
    required this.tierTypeLabel,
    required this.thresholdValue,
    required this.flatAmount,
    required this.perUnitAmount,
  });

  factory MaterialRateTierModel.fromJson(Map<String, dynamic> json) {
    return MaterialRateTierModel(
      tierType: json['tier_type']?.toString() ?? '',
      tierTypeLabel: json['tier_type_label']?.toString() ?? '',
      thresholdValue: json['threshold_value']?.toString(),
      flatAmount: json['flat_amount']?.toString() ?? '0.00',
      perUnitAmount: json['per_unit_amount']?.toString() ?? '0.0000',
    );
  }
}

class MaterialRateSetModel {
  final int id;
  final String category;
  final String categoryLabel;
  final String name;
  final bool isDefault;
  final String? minimumMeasure;
  final List<MaterialRateTierModel> tiers;

  MaterialRateSetModel({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.name,
    required this.isDefault,
    required this.minimumMeasure,
    required this.tiers,
  });

  factory MaterialRateSetModel.fromJson(Map<String, dynamic> json) {
    return MaterialRateSetModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      category: json['category']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isDefault: json['is_default'] == true,
      minimumMeasure: json['minimum_measure']?.toString(),
      tiers: (json['tiers'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MaterialRateTierModel.fromJson)
          .toList(),
    );
  }
}

/// Same shape as ProjectMaterialModel but for the global Library catalog
/// (not scoped to one project's assignments) - reuses the rate set/tier
/// models since the server serializes both the same way.
class LibraryMaterialModel {
  final int id;
  final String name;
  final String materialGroup;
  final String inputTypeLabel;
  final String unitLabel;
  final String manufacturer;
  final String productCode;
  final String statusLabel;
  final List<MaterialRateSetModel> rateSets;

  LibraryMaterialModel({
    required this.id,
    required this.name,
    required this.materialGroup,
    required this.inputTypeLabel,
    required this.unitLabel,
    required this.manufacturer,
    required this.productCode,
    required this.statusLabel,
    required this.rateSets,
  });

  factory LibraryMaterialModel.fromJson(Map<String, dynamic> json) {
    return LibraryMaterialModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      materialGroup: json['material_group']?.toString() ?? '',
      inputTypeLabel: json['input_type_label']?.toString() ?? '',
      unitLabel: json['unit_label']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      rateSets: (json['rate_sets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MaterialRateSetModel.fromJson)
          .toList(),
    );
  }
}

class ProjectMaterialModel {
  final int id;
  final String name;
  final String materialGroup;
  final String inputTypeLabel;
  final String unitLabel;
  final String manufacturer;
  final String productCode;
  final String statusLabel;
  final List<MaterialRateSetModel> rateSets;

  ProjectMaterialModel({
    required this.id,
    required this.name,
    required this.materialGroup,
    required this.inputTypeLabel,
    required this.unitLabel,
    required this.manufacturer,
    required this.productCode,
    required this.statusLabel,
    required this.rateSets,
  });

  factory ProjectMaterialModel.fromJson(Map<String, dynamic> json) {
    return ProjectMaterialModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      materialGroup: json['material_group']?.toString() ?? '',
      inputTypeLabel: json['input_type_label']?.toString() ?? '',
      unitLabel: json['unit_label']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? '',
      statusLabel: json['status_label']?.toString() ?? '',
      rateSets: (json['rate_sets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MaterialRateSetModel.fromJson)
          .toList(),
    );
  }
}
