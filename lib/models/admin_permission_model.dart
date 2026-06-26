class AdminRole {
  final int id;
  final String name;
  final String description;
  final bool isSystem;

  AdminRole({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
  });

  factory AdminRole.fromJson(Map<String, dynamic> json) {
    return AdminRole(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isSystem: json['is_system'] ?? false,
    );
  }
}

class PermissionItem {
  String menuKey;
  bool canView;
  bool canCreate;
  bool canEdit;
  bool canDelete;

  PermissionItem({
    required this.menuKey,
    required this.canView,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
  });

  factory PermissionItem.fromJson(String key, Map<String, dynamic> json) {
    return PermissionItem(
      menuKey: key,
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
