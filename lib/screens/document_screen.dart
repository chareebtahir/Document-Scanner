import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_document.dart';
import '../models/scan_page.dart';
import '../services/document_store.dart';
import '../services/settings_store.dart';
import '../widgets/dialogs.dart';
import '../widgets/document_actions.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_import.dart';
import '../widgets/page_thumbnail.dart';
import 'edit_page_screen.dart';
import 'page_viewer_screen.dart';

enum _MenuAction { rename, shareImages, delete }

class DocumentScreen extends StatefulWidget {
  final String documentId;
  const DocumentScreen({super.key, required this.documentId});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final _store = DocumentStore.instance;
  bool _reordering = false;

  Future<void> _addPages(ScanDocument doc) async {
    final pages = await importPages(context);
    if (pages.isEmpty) return;
    await _store.addPages(doc, pages);
    if (mounted) {
      showMessage(context,
          '${pages.length} page${pages.length == 1 ? '' : 's'} added');
    }
  }

  void _view(ScanDocument doc, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              PageViewerScreen(documentId: doc.id, initialIndex: index)),
    );
  }

  Future<void> _edit(ScanPage page) async {
    await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => EditPageScreen(page: page)));
  }

  Future<void> _deletePage(ScanDocument doc, ScanPage page) async {
    if (SettingsStore.instance.confirmDelete) {
      final ok = await confirmAction(context,
          title: 'Delete page ${doc.pages.indexOf(page) + 1}?',
          message: 'This page will be removed from "${doc.name}".');
      if (!ok) return;
    }
    await _store.deletePage(doc, page);
    if (mounted) showMessage(context, 'Page deleted');
  }

  Future<void> _onMenu(_MenuAction action, ScanDocument doc) async {
    switch (action) {
      case _MenuAction.rename:
        await DocumentActions.rename(context, doc);
        break;
      case _MenuAction.shareImages:
        await DocumentActions.shareImages(context, doc);
        break;
      case _MenuAction.delete:
        final deleted = await DocumentActions.delete(context, doc);
        if (deleted && mounted) Navigator.pop(context);
        break;
    }
  }

  void _pageOptions(ScanDocument doc, ScanPage page) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                _view(doc, doc.pages.indexOf(page));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit (crop, rotate, adjust)'),
              onTap: () {
                Navigator.pop(context);
                _edit(page);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_vert),
              title: const Text('Reorder pages'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _reordering = true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete page'),
              onTap: () {
                Navigator.pop(context);
                _deletePage(doc, page);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final doc = _store.byId(widget.documentId);
        if (doc == null) {
          return const Scaffold(body: Center(child: Text('Document not found')));
        }
        final date = DateFormat('d MMM yyyy, h:mm a').format(doc.updatedAt);
        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => DocumentActions.rename(context, doc),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.name, overflow: TextOverflow.ellipsis),
                  Text('${doc.pages.length} page(s)  ·  $date',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            actions: [
              if (doc.pages.length > 1)
                IconButton(
                  tooltip: _reordering ? 'Done' : 'Reorder pages',
                  icon: Icon(_reordering ? Icons.check : Icons.swap_vert),
                  onPressed: () => setState(() => _reordering = !_reordering),
                ),
              PopupMenuButton<_MenuAction>(
                onSelected: (a) => _onMenu(a, doc),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: _MenuAction.rename,
                      child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Rename'))),
                  PopupMenuItem(
                      value: _MenuAction.shareImages,
                      child: ListTile(
                          leading: Icon(Icons.image_outlined),
                          title: Text('Share as images'))),
                  PopupMenuItem(
                      value: _MenuAction.delete,
                      child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete document'))),
                ],
              ),
            ],
          ),
          body: doc.pages.isEmpty
              ? EmptyState(
                  icon: Icons.note_add_outlined,
                  title: 'No pages',
                  message: 'This document is empty. Add a page to continue.',
                  action: FilledButton.icon(
                    onPressed: () => _addPages(doc),
                    icon: const Icon(Icons.add),
                    label: const Text('Add page'),
                  ),
                )
              : _reordering
                  ? _buildReorderList(doc)
                  : _buildGrid(doc),
          bottomNavigationBar: _reordering || doc.pages.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addPages(doc),
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Add'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () =>
                                DocumentActions.exportPdf(context, doc),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('PDF'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                DocumentActions.sharePdf(context, doc),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildGrid(ScanDocument doc) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: doc.pages.length,
      itemBuilder: (context, i) {
        final page = doc.pages[i];
        return Card(
          child: InkWell(
            onTap: () => _view(doc, i),
            onLongPress: () => _pageOptions(doc, page),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageThumbnail(path: page.processedPath, number: i + 1),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Page options',
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _pageOptions(doc, page),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderList(ScanDocument doc) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 10),
              Expanded(
                  child: Text('Hold and drag the handle to change page order.')),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            buildDefaultDragHandles: false,
            itemCount: doc.pages.length,
            onReorderItem: (oldIndex, newIndex) =>
                _store.reorderPages(doc, oldIndex, newIndex),
            itemBuilder: (context, i) {
              final page = doc.pages[i];
              return Card(
                key: ValueKey(page.id),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                        width: 48,
                        height: 64,
                        child: PageThumbnail(path: page.processedPath)),
                  ),
                  title: Text('Page ${i + 1}'),
                  subtitle: Text(page.isEdited ? 'Edited' : 'Original'),
                  trailing: ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
