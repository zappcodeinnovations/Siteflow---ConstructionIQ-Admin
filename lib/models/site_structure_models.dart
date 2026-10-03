class SiteZoneModel {
  final int id;
  final String name;
  final String zoneCore;

  SiteZoneModel({required this.id, required this.name, required this.zoneCore});

  factory SiteZoneModel.fromJson(Map<String, dynamic> json) {
    return SiteZoneModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      zoneCore: json['zone_core']?.toString() ?? '',
    );
  }
}

class SiteLevelModel {
  final int id;
  final String name;
  final String drawingUrl;
  final List<SiteZoneModel> zones;
  final int drawingCount;

  SiteLevelModel({
    required this.id,
    required this.name,
    required this.drawingUrl,
    required this.zones,
    required this.drawingCount,
  });

  factory SiteLevelModel.fromJson(Map<String, dynamic> json) {
    return SiteLevelModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      drawingUrl: json['drawing_url']?.toString() ?? '',
      zones: (json['zones'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SiteZoneModel.fromJson)
          .toList(),
      drawingCount: (json['drawings'] as List<dynamic>? ?? []).length,
    );
  }
}

class SiteBlockModel {
  final int id;
  final String name;
  final List<SiteLevelModel> levels;

  SiteBlockModel({required this.id, required this.name, required this.levels});

  factory SiteBlockModel.fromJson(Map<String, dynamic> json) {
    return SiteBlockModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      levels: (json['levels'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SiteLevelModel.fromJson)
          .toList(),
    );
  }

  static List<SiteBlockModel> listFromRaw(List<dynamic>? raw) {
    if (raw == null) return [];
    return raw.whereType<Map<String, dynamic>>().map(SiteBlockModel.fromJson).toList();
  }
}
