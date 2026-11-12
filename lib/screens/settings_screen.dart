import 'package:flutter/material.dart';

import '../models/scan_page.dart';
import '../services/document_store.dart';
import '../services/settings_store.dart';
import '../widgets/dialogs.dart';
import 'about_screen.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<T?> _choose<T>(BuildContext context, String title, List<T> options,
      T current, String Function(T) label) {
    return showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: options
            .map((o) => ListTile(
                  title: Text(label(o)),
                  trailing: o == current
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, o),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _clearAll(BuildContext context) async {
    final store = DocumentStore.instance;
    final ok = await confirmAction(context,
        title: 'Delete everything?',
        message:
            'All ${store.documents.length} documents, their pages and saved PDFs will be deleted from this phone. This cannot be undone.',
        confirmLabel: 'Delete all');
    if (!ok || !context.mounted) return;
    await store.clearAll();
    await SettingsStore.instance.reset();
    if (context.mounted) showMessage(context, 'All data deleted');
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _Header('Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('System')),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Light')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Dark')),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => s.setThemeMode(v.first),
              ),
            ),
            const _Header('Scanning'),
            ListTile(
              leading: const Icon(Icons.filter_b_and_w),
              title: const Text('Default filter for new pages'),
              subtitle: Text(s.defaultFilter.label),
              onTap: () async {
                final v = await _choose(context, 'Default filter',
                    PageFilter.values, s.defaultFilter, (f) => f.label);
                if (v != null) s.setDefaultFilter(v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.high_quality_outlined),
              title: const Text('Image quality'),
              subtitle: Text(s.quality.label),
              onTap: () async {
                final v = await _choose(context, 'Image quality',
                    ScanQuality.values, s.quality, (q) => q.label);
                if (v != null) s.setQuality(v);
              },
            ),
            const _Header('PDF'),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Page size'),
              subtitle: Text(s.pageSize.label),
              onTap: () async {
                final v = await _choose(context, 'Page size',
                    PdfPageSize.values, s.pageSize, (p) => p.label);
                if (v != null) s.setPageSize(v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.border_outer),
              title: const Text('Page margin'),
              subtitle: Text(s.margin.label),
              onTap: () async {
                final v = await _choose(context, 'Page margin',
                    PdfMargin.values, s.margin, (m) => m.label);
                if (v != null) s.setMargin(v);
              },
            ),
            const _Header('General'),
            SwitchListTile(
              secondary: const Icon(Icons.warning_amber_outlined),
              title: const Text('Ask before deleting'),
              subtitle: const Text('Show a confirmation for every delete'),
              value: s.confirmDelete,
              onChanged: s.setConfirmDelete,
            ),
            ListTile(
              leading: const Icon(Icons.slideshow_outlined),
              title: const Text('Show introduction again'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen())),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete all data',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              subtitle: const Text('Documents, pages, PDFs and settings'),
              onTap: () => _clearAll(context),
            ),
            const _Header('About'),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About this app'),
              subtitle: const Text('Version, team and university'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              fontSize: 12)),
    );
  }
}
