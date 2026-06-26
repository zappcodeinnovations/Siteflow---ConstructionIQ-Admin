class AdminNotification {
  final int id;
  final String headline;
  final String notificationText;
  final String audience;
  final bool isForAllOperators;
  final List<int> operatorIds;
  final int operatorCount;
  final String attachmentUrl;
  final String attachmentName;
  final bool isActive;
  final String sentAt;
  final int fcmSuccessCount;
  final int fcmFailureCount;
  final String fcmError;
  final String createdByName;
  final String updatedByName;
  final String createdAt;
  final String updatedAt;

  AdminNotification({
    required this.id,
    required this.headline,
    required this.notificationText,
    required this.audience,
    required this.isForAllOperators,
    required this.operatorIds,
    required this.operatorCount,
    required this.attachmentUrl,
    required this.attachmentName,
    required this.isActive,
    required this.sentAt,
    required this.fcmSuccessCount,
    required this.fcmFailureCount,
    required this.fcmError,
    required this.createdByName,
    required this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    var opIds = json['operator_ids'] as List? ?? [];
    return AdminNotification(
      id: json['id'] ?? 0,
      headline: json['headline'] ?? '',
      notificationText: json['notification_text'] ?? '',
      audience: json['audience'] ?? '',
      isForAllOperators: json['is_for_all_operators'] ?? false,
      operatorIds: opIds.map((e) => e as int).toList(),
      operatorCount: json['operator_count'] ?? 0,
      attachmentUrl: json['attachment_url'] ?? '',
      attachmentName: json['attachment_name'] ?? '',
      isActive: json['is_active'] ?? false,
      sentAt: json['sent_at'] ?? '',
      fcmSuccessCount: json['fcm_success_count'] ?? 0,
      fcmFailureCount: json['fcm_failure_count'] ?? 0,
      fcmError: json['fcm_error'] ?? '',
      createdByName: json['created_by_name'] ?? '',
      updatedByName: json['updated_by_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String get formattedUpdatedAt {
    try {
      if (updatedAt.isEmpty) return '';
      final parsed = DateTime.parse(updatedAt);
      // Wait, we can't use intl.dart here because we previously removed it from the project (it wasn't in pubspec.yaml).
      // We'll format manually.
      return _formatDateTime(parsed);
    } catch (e) {
      return updatedAt;
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    var hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    
    final dayStr = dt.day.toString().padLeft(2, '0');
    final monthStr = months[dt.month - 1];
    final yearStr = dt.year.toString();
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');

    return "Updated $dayStr $monthStr $yearStr, $hourStr:$minStr $amPm";
  }
}

class AdminNotificationResponse {
  final bool status;
  final String message;
  final int count;
  final List<AdminNotification> data;

  AdminNotificationResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory AdminNotificationResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List? ?? [];
    return AdminNotificationResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      count: json['count'] ?? 0,
      data: dataList.map((i) => AdminNotification.fromJson(i)).toList(),
    );
  }
}
