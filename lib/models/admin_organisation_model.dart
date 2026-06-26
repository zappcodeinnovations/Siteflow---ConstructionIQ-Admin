class AdminOrganisation {
  final int id;
  final String name;
  final String currency;

  AdminOrganisation({
    required this.id,
    required this.name,
    required this.currency,
  });

  factory AdminOrganisation.fromJson(Map<String, dynamic> json) {
    return AdminOrganisation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      currency: json['currency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "currency": currency,
    };
  }
}
