import 'package:flutter/material.dart';

import '../widgets/offline_badge.dart';

typedef _Material = ({String module, String title, bool cached});

/// Course Materials (D3 Figure 4): files grouped by module, each marked
/// "Cached" when it is stored on the phone, plus a low-storage hint.
/// Uses placeholder data until LocalDbService is built.
class CourseMaterialsScreen extends StatelessWidget {
  const CourseMaterialsScreen({super.key});

  // Placeholder data from the wireframe.
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

  @override
  Widget build(BuildContext context) {
    final modules = {for (final material in _materials) material.module}.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Materials'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OfflineBadge(isOnline: true),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final module in modules) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                module,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final material in _materials.where((m) => m.module == module))
              Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(material.title),
                  trailing: material.cached
                      ? const Chip(label: Text('Cached'))
                      : const Icon(Icons.cloud_download_outlined),
                  onTap: () => _openMaterial(context, material),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const ListTile(
              leading: Icon(Icons.storage_outlined),
              title: Text('Low storage'),
              subtitle: Text('Try removing older items?'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cached items open with zero network latency',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}