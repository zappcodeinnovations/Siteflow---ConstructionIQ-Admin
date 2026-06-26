import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/project_model.dart';
import '../../models/project_all_in_one_model.dart';
import '../../models/announcement_model.dart';

class ProjectController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Project> _projects = [];
  List<Project> get projects => _projects;

  List<Project> _filteredProjects = [];
  List<Project> get filteredProjects => _filteredProjects;

  List<int> _selectedProjectIds = [];
  List<int> get selectedProjectIds => _selectedProjectIds;

  Future<void> fetchProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.projects);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> projectList = data['data'];
        _projects = projectList.map((json) => Project.fromJson(json)).toList();
        _filteredProjects = List.from(_projects);
        _selectedProjectIds.clear();
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch projects';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Project?> fetchProjectDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.projectDetails(id));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> projectList = data['data'];
        if (projectList.isNotEmpty) {
          final project = Project.fromJson(projectList.first);
          _isLoading = false;
          notifyListeners();
          return project;
        }
      }
      _errorMessage = data['message'] ?? 'Failed to fetch project details';
      return null;
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProjectAllInOneModel?> fetchAllInOneProjectDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.projectAllInOneDetails(id));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final allInOneData = ProjectAllInOneModel.fromJson(data['data']);
        _isLoading = false;
        notifyListeners();
        return allInOneData;
      }
      _errorMessage = data['message'] ?? 'Failed to fetch all-in-one project details';
      return null;
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProject(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.delete(ApiEndpoints.baseUrl + ApiEndpoints.projectDetails(id));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _projects.removeWhere((project) => project.id == id);
        _filteredProjects.removeWhere((project) => project.id == id);
        _selectedProjectIds.remove(id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to delete project';
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchAssignments(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.projectAssignments(id));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _isLoading = false;
        notifyListeners();
        return data['data'];
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch assignments';
        return null;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignProject(int id, {int? contractorId, List<int>? teamIds, List<int>? workerIds}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.baseUrl + ApiEndpoints.projectAssignments(id),
        body: {
          if (contractorId != null) 'contractor_id': contractorId,
          if (teamIds != null) 'team_ids': teamIds,
          if (workerIds != null) 'worker_ids': workerIds,
        },
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to update assignments';
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement(int projectId, String title, String message, bool isActive) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.baseUrl + ApiEndpoints.announcements,
        body: {
          'project_id': projectId,
          'title': title,
          'message': message,
          'is_active': isActive,
        },
      );
      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to create announcement';
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<Announcement?> fetchAnnouncementDetails(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.announcementDetails(id));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        _isLoading = false;
        notifyListeners();
        return Announcement.fromJson(data['data']);
      } else {
        _errorMessage = data['message'] ?? 'Failed to fetch announcement details';
        return null;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchProjects(String query) {
    if (query.isEmpty) {
      _filteredProjects = List.from(_projects);
    } else {
      _filteredProjects = _projects.where((project) {
        final searchStr = '${project.code} ${project.name}'.toLowerCase();
        return searchStr.contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selectedProjectIds.contains(id)) {
      _selectedProjectIds.remove(id);
    } else {
      _selectedProjectIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(bool select) {
    if (select) {
      _selectedProjectIds = _filteredProjects.map((e) => e.id).toList();
    } else {
      _selectedProjectIds.clear();
    }
    notifyListeners();
  }

  Future<bool> createProject(String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        ApiEndpoints.baseUrl + ApiEndpoints.projects,
        body: {'name': name},
      );
      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == true) {
        final newProject = Project.fromJson(data['data']);
        _projects.insert(0, newProject);
        _filteredProjects.insert(0, newProject);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to create project';
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

  Future<bool> deleteSelectedProjects() async {
    if (_selectedProjectIds.isEmpty) return true;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool allSuccess = true;
    try {
      final idsToDelete = List<int>.from(_selectedProjectIds);
      for (final id in idsToDelete) {
        final response = await ApiClient.delete(ApiEndpoints.baseUrl + ApiEndpoints.projectDetails(id));
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['status'] == true) {
          _projects.removeWhere((project) => project.id == id);
          _filteredProjects.removeWhere((project) => project.id == id);
          _selectedProjectIds.remove(id);
        } else {
          allSuccess = false;
          _errorMessage = data['message'] ?? 'Failed to delete some projects';
        }
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      allSuccess = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    
    return allSuccess;
  }
}
