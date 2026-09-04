class AdminTeam {
  final int id;
  final String name;
  final String displayName;
  final String nickname;
  final int? leadId;
  final String? leadName;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final String shiftTimezone;
  final int memberCount;
  final DateTime? createdAt;

  AdminTeam({
    required this.id,
    required this.name,
    required this.displayName,
    required this.nickname,
    required this.leadId,
    required this.leadName,
    required this.shiftStartTime,
    required this.shiftEndTime,
    required this.shiftTimezone,
    required this.memberCount,
    required this.createdAt,
  });

  factory AdminTeam.fromJson(Map<String, dynamic> json) {
    return AdminTeam(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? json['name'] ?? '',
      nickname: json['nickname'] ?? '',
      leadId: json['lead_id'],
      leadName: json['lead_name'],
      shiftStartTime: json['shift_start_time'],
      shiftEndTime: json['shift_end_time'],
      shiftTimezone: json['shift_timezone'] ?? '',
      memberCount: json['member_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
