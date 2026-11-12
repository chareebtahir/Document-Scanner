import 'package:flutter/material.dart';

import '../models/scan_page.dart';
import '../services/document_store.dart';
import '../services/image_source_picker.dart';
import '../widgets/dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_import.dart';
import '../widgets/page_thumbnail.dart';
import 'document_screen.dart';
import 'edit_page_screen.dart';

/// Collects pages for a new document before it is saved.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final List<ScanPage> _pages = [];

  Future<void> _add(ScanSource source) async {
    final pages = await importPages(context, source: source);
    if (pages.isEmpty) return;
    setState(() => _pages.addAll(pages));
    if (mounted) {
      showMessage(context,
          '${pages.length} page${pages.length == 1 ? '' : 's'} added');
    }
  }

  Future<void> _edit(ScanPage page) async {
    final changed = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => EditPageScreen(page: page)));
    if (changed == true) setState(() {});
  }

  Future<void> _remove(ScanPage page) async {
    setState(() => _pages.remove(page));
    await DocumentStore.instance.discardPages([page]);
  }

  Future<void> _save() async {
    final store = DocumentStore.instance;
    final name = await showNameDialog(context,
        title: 'Save document', initial: store.suggestName());
    if (name == null || !mounted) return;
    final doc = await store.createDocument(name, _pages);
    _pages.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => DocumentScreen(documentId: doc.id)));
  }

  Future<void> _onBack() async {
    final discard = await confirmAction(context,
        title: 'Discard scan?',
        message:
            'The ${_pages.length} page(s) you added have not been saved yet.',
        confirmLabel: 'Discard');
    if (!discard) return;
    await DocumentStore.instance.discardPages(_pages);
    _pages.clear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pages.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New scan'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _pages.isEmpty ? null : _save,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
        body: _pages.isEmpty
            ? const EmptyState(
                icon: Icons.add_a_photo_outlined,
                title: 'Add your first page',
                message:
                    'Use the camera to scan a paper page, or import photos you already have.',
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Text('${_pages.length} page(s)',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('Tap a page to edit it',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: _pages.length,
                      itemBuilder: (context, i) {
                        final page = _pages[i];
                        return Card(
                          child: InkWell(
                            onTap: () => _edit(page),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                PageThumbnail(
                                    path: page.processedPath, number: i + 1),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton.filledTonal(
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Remove page',
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => _remove(page),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _add(ScanSource.camera),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Camera'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _add(ScanSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
