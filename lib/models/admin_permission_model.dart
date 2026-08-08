class AdminRole {
  final String id;
  final String name;
  final String description;
  final bool isSystem;
  final String code;

  AdminRole({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.code,
  });

  factory AdminRole.fromJson(Map<String, dynamic> json) {
    return AdminRole(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isSystem: json['is_system'] ?? false,
      code: json['code'] ?? '',
    );
  }
}

class PermissionItem {
  String menuKey;
  String label;
  bool canView;
  bool canCreate;
  bool canEdit;
  bool canDelete;

  PermissionItem({
    required this.menuKey,
    this.label = '',
    required this.canView,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
  });

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    return PermissionItem(
      menuKey: json['menu_key'] ?? '',
      label: json['label'] ?? '',
      canView: json['view'] ?? false,
      canCreate: json['create'] ?? false,
      canEdit: json['edit'] ?? false,
      canDelete: json['delete'] ?? false,
    );
  }

  Map<String, dynamic> toJsonValue() {
    return {
      "view": canView,
      "create": canCreate,
      "edit": canEdit,
      "delete": canDelete,
    };
  }
}
