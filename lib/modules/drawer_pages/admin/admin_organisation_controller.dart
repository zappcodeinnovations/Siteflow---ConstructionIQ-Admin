import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/admin_organisation_model.dart';

class AdminOrganisationController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AdminOrganisation? _organisation;
  AdminOrganisation? get organisation => _organisation;

  List<String> _currencies = ['GBP']; // default fallback
  List<String> get currencies => _currencies;

  Future<void> fetchCurrencies() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/api/admin/organisation/currency-options/';
      final response = await ApiClient.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          _currencies = (decoded['data'] as List).map((c) => c['code'].toString()).toList();
        }
      }
    } catch (e) {
      print("Error fetching currencies: $e");
    }
    notifyListeners();
  }

  Future<void> fetchOrganisation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/api/admin/organisation/';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
           _organisation = AdminOrganisation.fromJson(decoded['data']);
        }
      } else {
        _errorMessage = 'Failed to load organisation settings.';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> saveOrganisation(String name, String currency) async {
    _isSaving = true;
    notifyListeners();

    try {
      final url = '${ApiEndpoints.baseUrl}/api/admin/organisation/';
      final payload = {
        "name": name,
        "currency": currency,
      };

      // Assuming PUT/PATCH or POST for updating
      final response = await ApiClient.patch(url, body: payload); 
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh local data
        await fetchOrganisation();
        return {"success": true, "message": "Organisation settings saved successfully."};
      }
      return {"success": false, "message": "Failed to save organisation settings."};
    } catch (e) {
      return {"success": false, "message": "An error occurred: $e"};
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
