import 'package:flutter/material.dart';
import '../models/course_material.dart';
import '../services/local_db_service.dart';
import '../widgets/dashed_border_painter.dart';
import '../widgets/portal_app_bar.dart';

class CourseMaterialsScreen extends StatefulWidget {
  const CourseMaterialsScreen({super.key});

  @override
  State<CourseMaterialsScreen> createState() => _CourseMaterialsScreenState();
}

class _CourseMaterialsScreenState extends State<CourseMaterialsScreen> {
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

  final Future<List<CourseMaterial>> _materialsFuture =
      LocalDbService.instance.getCourseMaterials();

  void _openMaterial(CourseMaterial material) {
    final message = material.isCached
        ? 'Opening ${material.title}'
        : '${material.title} is not downloaded yet – it will download when you are online';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _materialTile(CourseMaterial material) {
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
                color: material.isCached ? _navy : _missingText,
              ),
            ),
          ),
          if (material.isCached)
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
        onTap: () => _openMaterial(material),
        child: material.isCached
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

  List<Widget> _groupedByModule(List<CourseMaterial> materials) {
    final modules = {for (final material in materials) material.moduleCode};
    return [
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
        for (final material in materials.where((m) => m.moduleCode == module))
          _materialTile(material),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PortalAppBar(title: 'Course Materials'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<List<CourseMaterial>>(
              future: _materialsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const Text('Could not load course materials from this device.');
                }
                final materials = snapshot.data!;
                if (materials.isEmpty) {
                  return const Text('No course materials yet.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _groupedByModule(materials),
                );
              },
            ),
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