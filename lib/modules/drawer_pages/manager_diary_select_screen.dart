import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import 'job_sheet_webview_screen.dart';
import 'manager_diary_controller.dart';

/// Mirrors the web's Manager Diary "select a sheet" step: pick which Library
/// Form to fill in as today's diary entry. The actual fill screen reuses the
/// same generic HTML form endpoint the web dashboard's iframe hits, with
/// ?manager_diary=1 so the backend treats it as a manager's own entry
/// (no job/project attached) instead of a rejected operative submission.
class ManagerDiarySelectScreen extends StatefulWidget {
  const ManagerDiarySelectScreen({super.key});

  @override
  State<ManagerDiarySelectScreen> createState() => _ManagerDiarySelectScreenState();
}

class _ManagerDiarySelectScreenState extends State<ManagerDiarySelectScreen> {
  final ManagerDiaryFormsController _controller = ManagerDiaryFormsController();

  @override
  void initState() {
    super.initState();
    _controller.fetchForms();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openForm(int formId, String formName) {
    final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.userFormHtml(formId)}?manager_diary=1';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobSheetWebviewScreen(url: url, title: formName)),
    ).then((_) {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          "Select a Sheet",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: BackgroundStripesPainter(isDark: isDark))),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.forms.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (_controller.errorMessage != null && _controller.forms.isEmpty) {
                  return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
                }
                if (_controller.forms.isEmpty) {
                  return const Center(child: Text("No fillable sheets available.", style: TextStyle(color: Colors.grey)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _controller.forms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final form = _controller.forms[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openForm(form.id, form.name),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFF0D6EFD).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(IconlyLight.document, color: isDark ? Colors.white : const Color(0xFF0D6EFD)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                form.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Icon(IconlyLight.arrow_right_2, size: 18, color: isDark ? Colors.white54 : Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
