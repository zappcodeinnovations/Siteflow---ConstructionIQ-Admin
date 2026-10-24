import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconly/iconly.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

/// The mobile equivalent of the web portal's **Project Admin** panel.
///
/// The API returns every option required for this form inside `project_setup`,
/// keeping the app's choices and the web portal's choices in sync.
class ProjectSetupTab extends StatefulWidget {
  final Map<String, dynamic>? projectSetup;
  final bool canEdit;
  final bool canManageGeofence;
  final int projectId;

  const ProjectSetupTab({
    super.key,
    required this.projectId,
    required this.canEdit,
    this.canManageGeofence = false,
    this.projectSetup,
  });

  @override
  State<ProjectSetupTab> createState() => _ProjectSetupTabState();
}

class _ProjectSetupTabState extends State<ProjectSetupTab> {
  final Map<String, dynamic> _changes = {};
  final Map<String, String> _displayOverrides = {};
  final Set<String> _selectedWorkerIds = <String>{};

  String? _selectedClientId;
  String? _selectedTemplateId;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedManagerId;
  String? _selectedSupervisorId;
  String? _selectedTeamId;
  String _workerQuery = '';
  bool _isSaving = false;
  bool _isGettingLocation = false;
  bool _initialized = false;
  bool _geofenceEnabled = true;

  Map<String, dynamic> get _setup => widget.projectSetup ?? const {};
  Map<String, dynamic> get _metadata =>
      Map<String, dynamic>.from(_setup['basic_metadata'] as Map? ?? const {});
  Map<String, dynamic> get _assignments =>
      Map<String, dynamic>.from(_setup['assignments'] as Map? ?? const {});
  Map<String, dynamic> get _dropdowns =>
      Map<String, dynamic>.from(_setup['dropdown_options'] as Map? ?? const {});

  @override
  void initState() {
    super.initState();
    _hydrateSelections();
  }

  @override
  void didUpdateWidget(covariant ProjectSetupTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectSetup != widget.projectSetup) _hydrateSelections();
  }

  void _hydrateSelections() {
    if (widget.projectSetup == null) return;
    final metadata = _metadata;
    final assignments = _assignments;
    final selectedTeams = assignments['selected_teams'] as List? ?? const [];
    final selectedWorkers =
        assignments['selected_workers'] as List? ?? const [];
    final contractor = assignments['contractor'] as Map?;
    final supervisor = assignments['site_supervisor'] as Map?;

    _selectedClientId = metadata['client_id']?.toString();
    _selectedTemplateId = metadata['template_id']?.toString();
    _selectedStatus = metadata['status']?.toString();
    _selectedPriority = metadata['priority']?.toString();
    _selectedManagerId = contractor?['id']?.toString();
    _selectedSupervisorId = supervisor?['id']?.toString();
    _selectedTeamId = selectedTeams.isEmpty
        ? null
        : selectedTeams.first['id']?.toString();
    _selectedWorkerIds
      ..clear()
      ..addAll(selectedWorkers.map((worker) => worker['id'].toString()));
    _geofenceEnabled = metadata['geofence_enabled'] != false;
    _initialized = true;
  }

  String? _fieldKey(String label) => const {
    'Project Name': 'name',
    'Description': 'description',
    'Site Address': 'site_address',
    'City': 'city',
    'State': 'state',
    'Country': 'country',
    'Postal Code': 'postal_code',
    'Latitude': 'latitude',
    'Longitude': 'longitude',
    'Geofence Radius (metres)': 'allowed_radius_meters',
    'Scheduled Clock-In Time': 'scheduled_clock_in_time',
    'Scheduled Clock-Out Time': 'scheduled_clock_out_time',
  }[label];

  String _valueFor(String label, dynamic apiValue) =>
      _displayOverrides[label] ?? apiValue?.toString() ?? '';

  List<Map<String, dynamic>> _items(String key) =>
      ((_dropdowns[key] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  Future<void> _saveProject() async {
    if (!widget.canEdit || _isSaving) return;
    setState(() => _isSaving = true);
    bool success = true;
    String message = 'Project saved successfully.';
    try {
      if (_changes.isNotEmpty) {
        final response = await ApiClient.patch(
          ApiEndpoints.baseUrl + ApiEndpoints.projectDetails(widget.projectId),
          body: _changes,
        );
        final data = _responseData(response.body);
        success = response.statusCode == 200 && data['status'] == true;
        message =
            data['message']?.toString() ??
            (success
                ? 'Project details saved.'
                : 'Project details could not be saved.');
        if (!success) return;
      }

      final assignmentResponse = await ApiClient.patch(
        ApiEndpoints.baseUrl +
            ApiEndpoints.projectAllInOneDetails(widget.projectId),
        body: {
          'module': 'project_setup',
          'contractor_id': _asInt(_selectedManagerId),
          'supervisor_id': _asInt(_selectedSupervisorId),
          'team_ids': _selectedTeamId == null
              ? <int>[]
              : [_asInt(_selectedTeamId)!],
          'worker_ids': _selectedWorkerIds
              .map(_asInt)
              .whereType<int>()
              .toList(),
        },
      );
      final assignmentData = _responseData(assignmentResponse.body);
      success =
          assignmentResponse.statusCode == 200 &&
          assignmentData['status'] == true;
      message =
          assignmentData['message']?.toString() ??
          (success
              ? 'Project saved successfully.'
              : 'Assignments could not be saved.');
      if (success) _changes.clear();
    } catch (_) {
      success = false;
      message =
          'Could not save the project. Check your connection and try again.';
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _responseData(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
    } catch (_) {
      return const {};
    }
  }

  int? _asInt(String? value) => value == null ? null : int.tryParse(value);

  Future<void> _useCurrentLocation() async {
    if (!widget.canEdit || _isGettingLocation) return;
    setState(() => _isGettingLocation = true);
    try {
      var enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled)
        throw const _LocationException(
          'Turn on location services to use your current location.',
        );
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _LocationException(
          'Location permission is required to use your current location.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _displayOverrides['Latitude'] = position.latitude.toStringAsFixed(8);
        _displayOverrides['Longitude'] = position.longitude.toStringAsFixed(8);
        _changes['latitude'] = _displayOverrides['Latitude'];
        _changes['longitude'] = _displayOverrides['Longitude'];
      });
    } on _LocationException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(
        'Current location could not be determined. Enter coordinates manually.',
      );
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickTime(String label, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? TimeOfDay.now().hour,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _displayOverrides[label] = value;
      _changes[_fieldKey(label)!] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projectSetup == null || !_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 980;
    final metadata = _metadata;

    final information = _section(
      context,
      title: 'Project Information',
      icon: IconlyLight.info_square,
      children: [
        _optionField(
          context,
          'Client',
          _selectedClientId,
          _items('available_clients'),
          (id) {
            setState(() {
              _selectedClientId = id;
              _changes['client_id'] = _asInt(id);
            });
          },
        ),
        const SizedBox(height: 16),
        _textField(context, 'Project Name', metadata['name']),
        const SizedBox(height: 16),
        _responsiveRow(context, [
          _optionField(
            context,
            'Status',
            _selectedStatus,
            _items('available_statuses'),
            (id) => setState(() {
              _selectedStatus = id;
              _changes['status'] = id;
            }),
          ),
          _optionField(
            context,
            'Priority',
            _selectedPriority,
            _items('available_priorities'),
            (id) => setState(() {
              _selectedPriority = id;
              _changes['priority'] = id;
            }),
          ),
        ]),
        const SizedBox(height: 16),
        _optionField(
          context,
          'Project Template',
          _selectedTemplateId,
          _items('available_templates'),
          (id) {
            setState(() {
              _selectedTemplateId = id;
              _changes['selected_template_ids'] = id == null
                  ? <int>[]
                  : [_asInt(id)!];
            });
          },
          allowClear: true,
        ),
        const SizedBox(height: 16),
        _textField(
          context,
          'Description',
          metadata['description'],
          maxLines: 4,
        ),
      ],
    );

    final location = _section(
      context,
      title: 'Location & Schedule',
      icon: IconlyLight.location,
      children: [
        _textField(
          context,
          'Site Address',
          metadata['site_address'],
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _responsiveRow(context, [
          _textField(context, 'City', metadata['city']),
          _textField(context, 'State', metadata['state']),
        ]),
        const SizedBox(height: 16),
        _responsiveRow(context, [
          _textField(context, 'Country', metadata['country']),
          _textField(context, 'Postal Code', metadata['postal_code']),
        ]),
        const SizedBox(height: 16),
        _textField(
          context,
          'Geofence Radius (metres)',
          metadata['allowed_radius_meters'],
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        if (widget.canManageGeofence)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Geofence enabled', style: _labelStyle(context)),
                    const SizedBox(height: 4),
                    Text(
                      'When off, this project\'s geofence is not enforced at all: '
                      'operatives can clock in/out from anywhere, even if no '
                      'project location is set above, and nobody is ever '
                      'auto-clocked-out for leaving the site.',
                      style: _mutedStyle(context),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _geofenceEnabled,
                  activeColor: const Color(0xFF0D6EFD),
                  onChanged: !widget.canEdit
                      ? null
                      : (value) => setState(() {
                          _geofenceEnabled = value;
                          _changes['geofence_enabled'] = value;
                        }),
                ),
              ),
            ],
          ),
        if (widget.canManageGeofence) const SizedBox(height: 16),
        _responsiveRow(context, [
          _timeField(
            context,
            'Scheduled Clock-In Time',
            metadata['scheduled_clock_in_time'],
          ),
          _timeField(
            context,
            'Scheduled Clock-Out Time',
            metadata['scheduled_clock_out_time'],
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'Operatives receive clock-in and clock-out reminders at these times.',
          style: _mutedStyle(context),
        ),
        const SizedBox(height: 20),
        Text('GPS Coordinates', style: _labelStyle(context)),
        const SizedBox(height: 8),
        _responsiveRow(context, [
          _textField(
            context,
            'Latitude',
            metadata['latitude'],
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          _textField(
            context,
            'Longitude',
            metadata['longitude'],
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: widget.canEdit && !_isGettingLocation
                  ? _useCurrentLocation
                  : null,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_outlined),
              label: const Text('Use Current Location'),
            ),
            OutlinedButton.icon(
              onPressed: widget.canEdit ? _saveProject : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Location'),
            ),
          ],
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Project Admin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _saveButton(compact: true),
            ],
          ),
          const SizedBox(height: 18),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      information,
                      const SizedBox(height: 20),
                      location,
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: _assignmentColumn(context)),
              ],
            )
          else ...[
            information,
            const SizedBox(height: 20),
            location,
            const SizedBox(height: 20),
            _assignmentColumn(context),
          ],
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: _saveButton()),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _assignmentColumn(BuildContext context) => Column(
    children: [
      _section(
        context,
        title: 'Project Assignments',
        icon: IconlyLight.profile,
        children: [
          _optionField(
            context,
            'Select Manager',
            _selectedManagerId,
            _items('available_managers'),
            (id) => setState(() => _selectedManagerId = id),
            allowClear: true,
          ),
          const SizedBox(height: 16),
          _optionField(
            context,
            'Select Site Supervisor',
            _selectedSupervisorId,
            _items('available_supervisors'),
            (id) => setState(() => _selectedSupervisorId = id),
            allowClear: true,
          ),
          const SizedBox(height: 16),
          _optionField(
            context,
            'Select Team',
            _selectedTeamId,
            _items('available_teams'),
            (id) => setState(() => _selectedTeamId = id),
            allowClear: true,
          ),
          const SizedBox(height: 20),
          Text('Select Worker', style: _labelStyle(context)),
          const SizedBox(height: 8),
          TextField(
            enabled: widget.canEdit,
            onChanged: (value) =>
                setState(() => _workerQuery = value.trim().toLowerCase()),
            style: TextStyle(color: _textColor(context)),
            decoration: _inputDecoration(
              context,
              hint: 'Search workers by name or email',
              prefix: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          _workerPicker(context),
        ],
      ),
      const SizedBox(height: 20),
      _currentTeamCard(context),
    ],
  );

  Widget _workerPicker(BuildContext context) {
    final workers = _items('available_workers').where((worker) {
      if (_workerQuery.isEmpty) return true;
      final name = _name(worker).toLowerCase();
      return name.contains(_workerQuery) ||
          (worker['email']?.toString().toLowerCase().contains(_workerQuery) ??
              false);
    }).toList();
    if (workers.isEmpty)
      return Text('No workers found.', style: _mutedStyle(context));
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: dark ? Colors.white24 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: workers.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: dark ? Colors.white12 : Colors.grey.shade200,
        ),
        itemBuilder: (_, index) {
          final worker = workers[index];
          final id = worker['id'].toString();
          return CheckboxListTile(
            dense: true,
            value: _selectedWorkerIds.contains(id),
            activeColor: Theme.of(context).colorScheme.primary,
            title: Text(
              _name(worker),
              style: TextStyle(
                color: _textColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              worker['email']?.toString() ?? '',
              style: _mutedStyle(context),
            ),
            onChanged: widget.canEdit
                ? (checked) => setState(() {
                    if (checked == true) {
                      _selectedWorkerIds.add(id);
                    } else {
                      _selectedWorkerIds.remove(id);
                    }
                  })
                : null,
          );
        },
      ),
    );
  }

  Widget _currentTeamCard(BuildContext context) {
    final people = <Map<String, dynamic>>[];
    void add(Map? person, String fallbackRole) {
      if (person == null ||
          person['id'] == null ||
          people.any((p) => p['id'].toString() == person['id'].toString()))
        return;
      people.add({...Map<String, dynamic>.from(person), '_role': fallbackRole});
    }

    final assignments = _assignments;
    add(assignments['contractor'] as Map?, 'Manager');
    add(assignments['site_supervisor'] as Map?, 'Site Supervisor');
    for (final worker in _items('available_workers')) {
      if (_selectedWorkerIds.contains(worker['id'].toString()))
        add(worker, 'Operative');
    }
    return _section(
      context,
      title: 'Current Team',
      icon: IconlyLight.user,
      children: [
        if (people.isEmpty)
          Text('No active assignees yet.', style: _mutedStyle(context)),
        ...people.map((person) => _personRow(context, person)),
      ],
    );
  }

  Widget _personRow(BuildContext context, Map<String, dynamic> person) {
    final name = _name(person);
    final initials = name
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .take(2)
        .map((item) => item[0])
        .join()
        .toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            child: Text(initials.isEmpty ? '?' : initials),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: _textColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  person['email']?.toString() ?? 'No email',
                  style: _mutedStyle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            person['_role']?.toString() ??
                person['role_label']?.toString() ??
                '',
            style: _mutedStyle(context),
          ),
        ],
      ),
    );
  }

  String _name(Map<String, dynamic> item) =>
      item['label']?.toString() ??
      item['display_name']?.toString() ??
      item['name']?.toString() ??
      item['role_label']?.toString() ??
      item['email']?.toString() ??
      'Unnamed member';

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? Colors.white24 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: _textColor(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _responsiveRow(BuildContext context, List<Widget> children) {
    if (MediaQuery.sizeOf(context).width < 620) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _textField(
    BuildContext context,
    String label,
    dynamic value, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final display = _valueFor(label, value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(context)),
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('$label-$display'),
          enabled: widget.canEdit,
          initialValue: display,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: _textColor(context)),
          onChanged: (input) {
            final key = _fieldKey(label);
            if (key != null) _changes[key] = input;
          },
          decoration: _inputDecoration(context),
        ),
      ],
    );
  }

  Widget _timeField(BuildContext context, String label, dynamic value) {
    final display = _valueFor(label, value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(context)),
        const SizedBox(height: 6),
        InkWell(
          onTap: widget.canEdit ? () => _pickTime(label, display) : null,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _inputDecoration(
              context,
              suffix: const Icon(Icons.access_time_outlined),
            ),
            child: Text(
              display.isEmpty ? 'Select time' : display,
              style: TextStyle(color: _textColor(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionField(
    BuildContext context,
    String label,
    String? value,
    List<Map<String, dynamic>> options,
    ValueChanged<String?> onChanged, {
    bool allowClear = false,
  }) {
    final valid = options.any(
      (item) => (item['id'] ?? item['value']).toString() == value,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(context)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: valid ? value : null,
          isExpanded: true,
          dropdownColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkSurface
              : Colors.white,
          style: TextStyle(color: _textColor(context)),
          decoration: _inputDecoration(context),
          hint: Text(
            'Select ${label.toLowerCase()}',
            style: _mutedStyle(context),
          ),
          items: [
            if (allowClear)
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Not assigned'),
              ),
            ...options.map(
              (item) => DropdownMenuItem<String>(
                value: (item['id'] ?? item['value']).toString(),
                child: Text(_name(item), overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: widget.canEdit ? onChanged : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: dark ? Colors.white24 : Colors.grey.shade300,
      ),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: _mutedStyle(context),
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: dark ? Colors.white.withOpacity(.05) : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.8,
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade300
        : Colors.grey.shade700,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  TextStyle _mutedStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade600,
    fontSize: 12,
  );
  Color _textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF18263B);

  Widget _saveButton({bool compact = false}) => ElevatedButton.icon(
    onPressed: widget.canEdit && !_isSaving ? _saveProject : null,
    icon: _isSaving
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : const Icon(Icons.save_outlined),
    label: Text(compact ? 'Save' : 'Save Project'),
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 24,
        vertical: 14,
      ),
      backgroundColor: const Color(0xFF0D6EFD),
      foregroundColor: Colors.white,
    ),
  );
}

class _LocationException implements Exception {
  final String message;
  const _LocationException(this.message);
}
