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
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      _filteredClients = List.from(_clients);
    } else {
      final queryTokens = trimmed
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      _filteredClients = _clients.where((client) {
        final name = client.name.toLowerCase();

        // 1. Direct contains match (fast path)
        if (name.contains(trimmed)) return true;

        // 2. Token / word matching
        if (queryTokens.isNotEmpty) {
          final matchesAllTokens = queryTokens.every((token) {
            if (name.contains(token)) return true;
            final nameWords = name.split(RegExp(r'\s+'));
            return nameWords.any((w) => _isFuzzyMatch(w, token));
          });
          if (matchesAllTokens) return true;
        }

        // 3. Whole phrase fuzzy matching
        return _isFuzzyMatch(name, trimmed);
      }).toList();
    }
    notifyListeners();
  }

  bool _isFuzzyMatch(String source, String target) {
    if (source.contains(target) || target.contains(source)) return true;
    
    // Normalized comparison removing adjacent duplicate characters (e.g. 'zaapkode' == 'zappkode' -> 'zapkode')
    final normSource = source.replaceAll(RegExp(r'(.)\1+'), r'$1');
    final normTarget = target.replaceAll(RegExp(r'(.)\1+'), r'$1');
    if (normSource.contains(normTarget) || normTarget.contains(normSource)) {
      return true;
    }

    // Levenshtein distance check for small typos
    if (target.length >= 3) {
      final distance = _levenshtein(source, target);
      if (distance <= 2) return true;
    }
    return false;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
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
        _clients.insert(0, newClient);
        _filteredClients.insert(0, newClient);
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
