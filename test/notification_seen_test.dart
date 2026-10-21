import 'package:euroside_admin/core/services/auth_service.dart';
import 'package:euroside_admin/core/services/notification_seen_service.dart';
import 'package:euroside_admin/models/admin_notification_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AdminNotification _n(int id, {bool active = true}) =>
    AdminNotification.fromJson({'id': id, 'is_active': active});

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    NotificationSeenService.lastSeenId.value = 0;
    await AuthService.saveUserRole(effectiveRole: 'manager', userId: 7);
    await NotificationSeenService.load();
  });

  test('badge counts only unseen active notifications', () async {
    final list = [_n(3), _n(2), _n(1, active: false)];
    expect(NotificationSeenService.unreadCount(list), 2);

    await NotificationSeenService.markSeen(list);
    expect(NotificationSeenService.unreadCount(list), 0);

    // A new alert arrives after the user has looked.
    expect(NotificationSeenService.unreadCount([_n(4), ...list]), 1);
  });

  test('seen state survives an app restart for the same user', () async {
    await NotificationSeenService.markSeen([_n(10)]);
    NotificationSeenService.lastSeenId.value = 0; // fresh process
    await NotificationSeenService.load();
    expect(NotificationSeenService.unreadCount([_n(10)]), 0);
  });

  test('another user on the same device has their own seen state', () async {
    await NotificationSeenService.markSeen([_n(10)]);
    await AuthService.saveUserRole(effectiveRole: 'admin', userId: 8);
    await NotificationSeenService.load();
    expect(NotificationSeenService.unreadCount([_n(10)]), 1);
  });
}
