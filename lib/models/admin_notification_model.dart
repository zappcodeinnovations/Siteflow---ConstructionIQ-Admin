import '../core/utils/date_helper.dart';

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

  // Was previously parsed and formatted by hand here without ever calling
  // .toLocal() - the backend sends UTC-aware ISO timestamps, so the raw
  // UTC clock fields were shown as-is instead of the device's local time
  // (e.g. a UK event at 14:30 UTC displayed as "14:30" instead of the
  // correct local time for whatever timezone the device is actually in).
  // DateHelper.formatToLocal() is the shared, already-correct helper used
  // everywhere else in the app for this.
  String get formattedUpdatedAt {
    if (updatedAt.isEmpty) return '';
    final formatted = DateHelper.formatToLocal(updatedAt, includeTime: true);
    return (formatted == '-' || formatted.isEmpty) ? '' : formatted;
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
