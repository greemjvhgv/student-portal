import 'package:flutter/material.dart';

class PortalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PortalAppBar({super.key, required this.title});

  final String title;

  static const Color navy = Color(0xFF0B2545);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.school, size: 20, color: Colors.white),
        ),
      ],
    );
  }
}