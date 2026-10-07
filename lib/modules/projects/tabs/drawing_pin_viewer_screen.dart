import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

/// Tap-to-place pin viewer for a single drawing, backed by the real
/// DrawingLocationsAPIView/DrawingLocationCreateAPIView/
/// DrawingLocationStatusUpdateAPIView endpoints - the web/app's "pins on a
/// drawing" feature that drawings_tab.dart never had any UI for.
class DrawingPinViewerScreen extends StatefulWidget {
  final int projectId;
  final String blockName;
  final String levelName;

  const DrawingPinViewerScreen({
    super.key,
    required this.projectId,
    required this.blockName,
    required this.levelName,
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
    'assigned': Colors.blue,
    'in_progress': Colors.orange,
    'qa_pending': Colors.purple,
    'approved': Colors.green,
    'failed': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/locations/?project_id=${widget.projectId}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        final all = (decoded['data'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        _matchingDrawings = all.where((d) {
          final block = (d['block'] as Map?)?['name']?.toString() ?? '';
          final level = (d['level'] as Map?)?['name']?.toString() ?? '';
          return block == widget.blockName && level == widget.levelName;
        }).toList();
      } else {
        _error = decoded['message']?.toString() ?? 'Failed to load drawing.';
      }
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _placePin(double x, double y) async {
    final drawing = _matchingDrawings[_selectedDrawingIndex];
    final titleController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("New Pin"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: "Title (optional)", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text("Add Pin")),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final url = '${ApiEndpoints.baseUrl}/drawing/locations/create/';
      final response = await ApiClient.post(url, body: {
        "drawing_id": drawing['id'],
        "x": x,
        "y": y,
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
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pin['title']?.toString() ?? pin['label']?.toString() ?? 'Pin', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(pin['reference_no']?.toString() ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text("Status: ${pin['status_label'] ?? status}"),
            if (pin['assigned_to_name'] != null) Text("Assigned to: ${pin['assigned_to_name']}"),
            const SizedBox(height: 16),
            const Text("Move to:", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _statusColors.keys.where((s) => s != status).map((s) {
                return ActionChip(
                  label: Text(s.replaceAll('_', ' ')),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _updatePinStatus(pin['id'] as int, s);
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
    return Scaffold(
      appBar: AppBar(title: Text('${widget.blockName} - ${widget.levelName} Pins')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _matchingDrawings.isEmpty
                  ? const Center(child: Text("No drawing uploaded for this level yet."))
                  : Column(
                      children: [
                        if (_matchingDrawings.length > 1)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: DropdownButton<int>(
                              value: _selectedDrawingIndex,
                              items: List.generate(
                                _matchingDrawings.length,
                                (i) => DropdownMenuItem(value: i, child: Text(_matchingDrawings[i]['name']?.toString() ?? 'Drawing ${i + 1}')),
                              ),
                              onChanged: (val) => setState(() => _selectedDrawingIndex = val ?? 0),
                            ),
                          ),
                        Expanded(child: _buildCanvas(_matchingDrawings[_selectedDrawingIndex])),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 12,
                            children: _statusColors.entries.map((e) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text(e.key.replaceAll('_', ' '), style: const TextStyle(fontSize: 11)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildCanvas(Map<String, dynamic> drawing) {
    final fileUrl = drawing['file_url']?.toString() ?? '';
    final widthPx = (drawing['image_width_px'] as num?)?.toDouble() ?? 1000;
    final heightPx = (drawing['image_height_px'] as num?)?.toDouble() ?? 1000;
    final pins = (drawing['locations'] as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

    if (fileUrl.isEmpty) {
      return const Center(child: Text("Drawing file is not available."));
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: AspectRatio(
          aspectRatio: widthPx / heightPx,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapUp: (details) {
                  final x = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                  final y = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                  _placePin(x, y);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      fileUrl,
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(IconlyLight.image, size: 64)),
                    ),
                    ...pins.map((pin) {
                      final x = (pin['x_coordinate'] as num?)?.toDouble() ?? 0;
                      final y = (pin['y_coordinate'] as num?)?.toDouble() ?? 0;
                      final color = _statusColors[pin['status']?.toString()] ?? Colors.blue;
                      return Positioned(
                        left: x * constraints.maxWidth - 12,
                        top: y * constraints.maxHeight - 12,
                        child: GestureDetector(
                          onTap: () => _showPinDetails(pin),
                          child: Tooltip(
                            message: pin['title']?.toString() ?? pin['reference_no']?.toString() ?? 'Pin',
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${pin['display_number'] ?? ''}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
