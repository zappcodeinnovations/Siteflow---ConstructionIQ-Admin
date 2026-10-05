import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/client_model.dart';

class ClientController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Client> _clients = [];
  List<Client> get clients => _clients;

  List<Client> _filteredClients = [];
  List<Client> get filteredClients => _filteredClients;

  Future<void> fetchClients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.clients);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> clientList = data['data'];
        _clients = clientList.map((json) => Client.fromJson(json)).toList();
        _filteredClients = List.from(_clients);
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch clients';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchClients(String query) {
    if (query.isEmpty) {
      _filteredClients = List.from(_clients);
    } else {
      _filteredClients = _clients
          .where((client) => client.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<bool> createClient(String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.baseUrl + ApiEndpoints.clients,
        body: {'name': name},
      );
      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == true) {
        final newClient = Client.fromJson(data['data']);
        _clients.add(newClient);
        _filteredClients.add(newClient);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to create client';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editClient(int id, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Assuming PUT or PATCH to /api/clients/id/
      final response = await ApiClient.put(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.clients}$id/',
        body: {'name': name},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        // Update in lists
        final updatedClient = Client(id: id, name: name);
        
        final index = _clients.indexWhere((c) => c.id == id);
        if (index != -1) _clients[index] = updatedClient;
        
        final filteredIndex = _filteredClients.indexWhere((c) => c.id == id);
        if (filteredIndex != -1) _filteredClients[filteredIndex] = updatedClient;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to update client';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClient(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.delete(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.clients}$id/',
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _clients.removeWhere((client) => client.id == id);
        _filteredClients.removeWhere((client) => client.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to delete client';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
