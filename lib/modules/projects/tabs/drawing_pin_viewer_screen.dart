import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';

/// Tap-to-place pin viewer for a single drawing, backed by the real
/// DrawingLocationsAPIView/DrawingLocationCreateAPIView/
/// DrawingLocationStatusUpdateAPIView endpoints.
class DrawingPinViewerScreen extends StatefulWidget {
  final int projectId;
  final String blockName;
  final String levelName;
  final Map<String, dynamic>? initialDrawing;

  const DrawingPinViewerScreen({
    super.key,
    required this.projectId,
    required this.blockName,
    required this.levelName,
    this.initialDrawing,
  });

  @override
  State<DrawingPinViewerScreen> createState() => _DrawingPinViewerScreenState();
}

class _DrawingPinViewerScreenState extends State<DrawingPinViewerScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _matchingDrawings = [];
  int _selectedDrawingIndex = 0;

  static const Map<String, Color> _statusColors = {
    'assigned': Color(0xFF0D6EFD),
    'in_progress': Color(0xFFF59E0B),
    'qa_pending': Color(0xFF8B5CF6),
    'approved': Color(0xFF10B981),
    'failed': Color(0xFFEF4444),
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialDrawing != null) {
      _matchingDrawings = [widget.initialDrawing!];
      _isLoading = false;
    }
    _load();
  }

  String _extractName(dynamic val) {
    if (val == null) return '';
    if (val is Map) return (val['name'] ?? val['title'] ?? val['label'] ?? '').toString();
    return val.toString();
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim()) ?? 0.0;
    }
    return 0.0;
  }

  String _resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final clean = url.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final base = ApiEndpoints.baseUrl.replaceAll('/api', '');
    return '$base${clean.startsWith('/') ? '' : '/'}$clean';
  }

  Future<void> _load() async {
    if (_matchingDrawings.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/locations/?project_id=${widget.projectId}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && (decoded['status'] == true || decoded is List || decoded.containsKey('data'))) {
        final all = (decoded['data'] as List? ?? (decoded is List ? decoded : [])).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

        final filtered = all.where((d) {
          final b = _extractName(d['block']).isNotEmpty ? _extractName(d['block']) : (d['block_name']?.toString() ?? '');
          final l = _extractName(d['level']).isNotEmpty ? _extractName(d['level']) : (d['level_name']?.toString() ?? '');
          if (b.toLowerCase().trim() == widget.blockName.toLowerCase().trim() &&
              l.toLowerCase().trim() == widget.levelName.toLowerCase().trim()) {
            return true;
          }
          if (l.toLowerCase().trim() == widget.levelName.toLowerCase().trim()) {
            return true;
          }
          return false;
        }).toList();

        if (filtered.isNotEmpty) {
          _matchingDrawings = filtered;
        } else if (all.isNotEmpty && _matchingDrawings.isEmpty) {
          _matchingDrawings = all;
        }
      } else {
        if (_matchingDrawings.isEmpty) {
          _error = decoded['message']?.toString() ?? 'Failed to load drawing.';
        }
      }
    } catch (e) {
      if (_matchingDrawings.isEmpty) {
        _error = 'An error occurred: $e';
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _placePin(double x, double y) async {
    if (_matchingDrawings.isEmpty) return;
    final drawing = _matchingDrawings[_selectedDrawingIndex];
    final titleController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("New Pin", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: "Pin Title / Note (optional)",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Add Pin"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/locations/create/';
      final drawingId = drawing['id'] ?? drawing['drawing_id'];
      final response = await ApiClient.post(url, body: {
        if (drawingId != null) "drawing_id": drawingId,
        "x": x,
        "y": y,
        "x_coordinate": x,
        "y_coordinate": y,
        if (titleController.text.trim().isNotEmpty) "title": titleController.text.trim(),
      });
      final decoded = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message']?.toString() ?? 'Failed to add pin.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add pin: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showPinDetails(Map<String, dynamic> pin) async {
    final status = pin['status']?.toString() ?? 'assigned';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _statusColors[status] ?? Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pin['title']?.toString() ?? pin['label']?.toString() ?? 'Pin ${pin['display_number'] ?? pin['id'] ?? ''}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (pin['reference_no'] != null && pin['reference_no'].toString().isNotEmpty)
              Text(
                "Ref: ${pin['reference_no']}",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
              ),
            const SizedBox(height: 12),
            Text("Status: ${pin['status_label'] ?? status.replaceAll('_', ' ')}", style: const TextStyle(fontWeight: FontWeight.w600)),
            if (pin['assigned_to_name'] != null && pin['assigned_to_name'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text("Assigned to: ${pin['assigned_to_name']}"),
            ],
            const SizedBox(height: 16),
            const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusColors.entries.where((e) => e.key != status).map((e) {
                return ActionChip(
                  avatar: Container(width: 8, height: 8, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                  label: Text(e.key.replaceAll('_', ' ')),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final pinId = pin['id'] is int ? pin['id'] as int : int.tryParse('${pin['id']}');
                    if (pinId != null) {
                      await _updatePinStatus(pinId, e.key);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePinStatus(int pinId, String newStatus) async {
    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/locations/$pinId/status/';
      final response = await ApiClient.post(url, body: {"status": newStatus});
      final decoded = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200) {
        await _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message']?.toString() ?? 'Failed to update pin.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update pin: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('${widget.blockName} - ${widget.levelName} Pins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text("Retry")),
                      ],
                    ),
                  ),
                )
              : _matchingDrawings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(IconlyLight.image, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              "No drawing uploaded for ${widget.blockName} > ${widget.levelName} yet.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Upload a site plan or drawing from the Drawings tab to view and place pins.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        if (_matchingDrawings.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: cardBg,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedDrawingIndex,
                                isExpanded: true,
                                dropdownColor: cardBg,
                                items: List.generate(
                                  _matchingDrawings.length,
                                  (i) {
                                    final dName = _matchingDrawings[i]['name']?.toString() ??
                                        _matchingDrawings[i]['title']?.toString() ??
                                        _matchingDrawings[i]['file_name']?.toString() ??
                                        'Drawing ${i + 1}';
                                    return DropdownMenuItem(value: i, child: Text(dName, style: const TextStyle(fontWeight: FontWeight.bold)));
                                  },
                                ),
                                onChanged: (val) => setState(() => _selectedDrawingIndex = val ?? 0),
                              ),
                            ),
                          ),
                        Expanded(
                          child: _buildCanvas(_matchingDrawings[_selectedDrawingIndex]),
                        ),
                        // Status Legend Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _statusColors.entries.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: e.value, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        e.key.replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildCanvas(Map<String, dynamic> drawing) {
    final rawFile = drawing['file_url'] ??
        drawing['file_path'] ??
        drawing['file'] ??
        drawing['image_url'] ??
        drawing['image'] ??
        drawing['url'] ??
        '';
    final fileUrl = _resolveUrl(rawFile.toString());
    final rawPins = drawing['locations'] ??
        drawing['pins'] ??
        drawing['drawing_locations'] ??
        drawing['drawing_pins'] ??
        [];
    final List<Map<String, dynamic>> pins =
        (rawPins is List ? rawPins : []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

    if (fileUrl.isEmpty) {
      return const Center(child: Text("Drawing file URL is not available."));
    }

    return InteractiveViewer(
      minScale: 0.2,
      maxScale: 6.0,
      boundaryMargin: const EdgeInsets.all(40),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapUp: (details) {
                final x = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                final y = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                _placePin(x, y);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    fileUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconlyLight.image, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text("Failed to load blueprint image", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(fileUrl, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                  ...pins.map((pin) {
                    double x = _parseDouble(pin['x_coordinate'] ?? pin['x'] ?? pin['coordinate_x'] ?? pin['x_coord']);
                    double y = _parseDouble(pin['y_coordinate'] ?? pin['y'] ?? pin['coordinate_y'] ?? pin['y_coord']);

                    if (x > 1.0 && x <= 100.0) x = x / 100.0;
                    if (y > 1.0 && y <= 100.0) y = y / 100.0;
                    x = x.clamp(0.0, 1.0);
                    y = y.clamp(0.0, 1.0);

                    final status = pin['status']?.toString() ?? 'assigned';
                    final color = _statusColors[status] ?? const Color(0xFF0D6EFD);
                    final displayNumber = pin['display_number']?.toString() ??
                        pin['pin_number']?.toString() ??
                        pin['reference_no']?.toString() ??
                        '${pins.indexOf(pin) + 1}';

                    return Positioned(
                      left: x * constraints.maxWidth - 14,
                      top: y * constraints.maxHeight - 14,
                      child: GestureDetector(
                        onTap: () => _showPinDetails(pin),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            displayNumber.length > 3 ? displayNumber.substring(displayNumber.length - 2) : displayNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
