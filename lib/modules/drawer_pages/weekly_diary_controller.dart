import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/weekly_diary_model.dart';

class WeeklyDiaryController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  WeeklyDiaryResponse? _data;
  WeeklyDiaryResponse? get data => _data;

  String? _week;

  Future<void> fetchWeek([String? week]) async {
    if (week != null) _week = week;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String url = ApiEndpoints.baseUrl + ApiEndpoints.weeklyDiary;
      if (_week != null && _week!.isNotEmpty) {
        url += '?week=$_week';
      }

      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded['status'] == true) {
        _data = WeeklyDiaryResponse.fromJson(decoded['data']);
        _week = _data!.weekStart;
      } else {
        _errorMessage = decoded['message'] ?? 'Failed to fetch weekly diary';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void goToPreviousWeek() {
    if (_data != null) fetchWeek(_data!.prevWeek);
  }

  void goToNextWeek() {
    if (_data != null) fetchWeek(_data!.nextWeek);
  }
}
