import 'package:flutter/material.dart';

import '../data/team.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = [
    'Scan with the camera or import from the gallery',
    'Crop, rotate, brightness and contrast',
    'Four filters: Original, Grayscale, B & W, Magic',
    'Multi-page documents with drag to reorder',
    'Rename, search and sort documents',
    'Save as PDF and share PDF or images',
    'Works fully offline. No account and no server',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.blue]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Image.asset('assets/images/comsats-logo.png', height: 96),
                const SizedBox(height: 14),
                const Text('Document Scanner',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Version $appVersion',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                const Text('$universityName\n$courseName',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Group members', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...teamMembers.map((m) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Text(m.name[0],
                        style: TextStyle(color: scheme.onPrimaryContainer)),
                  ),
                  title: Text(m.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${m.rollNo}\n${m.role}'),
                  isThreeLine: true,
                ),
              )),
          const SizedBox(height: 20),
          Text('Features', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: _features
                    .map((f) => ListTile(
                          dense: true,
                          leading: Icon(Icons.check_circle,
                              color: scheme.primary, size: 20),
                          title: Text(f),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
