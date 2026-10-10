import 'package:flutter/material.dart';
import '../widgets/portal_app_bar.dart';
import '../widgets/dashed_border_painter.dart';

typedef _Material = ({String module, String title, bool cached});

/// Course Materials (D3 Figure 4): files grouped by module. Cached files
/// have a blue box and "Cached ✓"; files not yet downloaded have a red
/// dashed box. Uses placeholder data until LocalDbService is built.
class CourseMaterialsScreen extends StatelessWidget {
  const CourseMaterialsScreen({super.key});

  static const _navy = PortalAppBar.navy;
  static const _cachedFill = Color(0xFFF4F9FC);
  static const _cachedBorder = Color(0xFF81D4FA);
  static const _cachedBlue = Color(0xFF29B6F6);
  static const _missingFill = Color(0xFFFFF1F1);
  static const _missingRed = Color(0xFFD32F2F);
  static const _missingText = Color(0xFFB71C1C);
  static const _warningFill = Color(0xFFFFFDE7);
  static const _warningBorder = Color(0xFFFFD54F);
  static const _warningText = Color(0xFF8D4A00);

  static const List<_Material> _materials = [
    (module: 'ITMDA3-34', title: 'Week 6 - Lecture Slides.pdf', cached: true),
    (module: 'ITMDA3-34', title: 'Study Guide - Databases.pdf', cached: false),
    (module: 'ITMTA3-33', title: 'Week 6 - Lecture Slides.pdf', cached: true),
    (module: 'ITMTA3-33', title: 'Week 6 - Course Slides.pdf', cached: true),
    (module: 'ITOPE3-33', title: 'Week 6 - Lecture Slides.pdf', cached: true),
  ];

  void _openMaterial(BuildContext context, _Material material) {
    final message = material.cached
        ? 'Opening ${material.title}'
        : '${material.title} is not downloaded yet – it will download when you are online';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _materialTile(BuildContext context, _Material material) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              material.title,
              style: TextStyle(
                fontSize: 16,
                letterSpacing: 0.6,
                color: material.cached ? _navy : _missingText,
              ),
            ),
          ),
          if (material.cached)
            const Text(
              'Cached ✓',
              style: TextStyle(fontSize: 16, color: _cachedBlue),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openMaterial(context, material),
        child: material.cached
            ? Container(
                decoration: BoxDecoration(
                  color: _cachedFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cachedBorder, width: 2),
                ),
                child: content,
              )
            : CustomPaint(
                foregroundPainter: const DashedBorderPainter(color: _missingRed),
                child: Container(
                  decoration: BoxDecoration(
                    color: _missingFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: content,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = {for (final material in _materials) material.module}.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PortalAppBar(title: 'Course Materials'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final module in modules) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  module,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ),
              for (final material in _materials.where((m) => m.module == module))
                _materialTile(context, material),
            ],
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _warningFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _warningBorder, width: 3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: _warningText),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Low storage try removing older items?',
                      style: TextStyle(color: _warningText, letterSpacing: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(indent: 24, endIndent: 24),
            const SizedBox(height: 4),
            const Text(
              'Cached items open with zero network latency',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
