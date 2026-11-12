import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scan_document.dart';
import '../services/document_store.dart';
import '../widgets/document_actions.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_thumbnail.dart';
import 'capture_screen.dart';
import 'document_screen.dart';

enum SortOrder { newest, oldest, nameAZ, mostPages }

extension SortOrderLabel on SortOrder {
  String get label => const {
        SortOrder.newest: 'Newest first',
        SortOrder.oldest: 'Oldest first',
        SortOrder.nameAZ: 'Name (A to Z)',
        SortOrder.mostPages: 'Most pages',
      }[this]!;
}

enum _DocAction { open, rename, exportPdf, share, delete }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = DocumentStore.instance;
  final _search = TextEditingController();
  String _query = '';
  SortOrder _sort = SortOrder.newest;
  bool _grid = true;

  List<ScanDocument> get _visible {
    final list = _store.documents
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    switch (_sort) {
      case SortOrder.newest:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortOrder.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortOrder.nameAZ:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOrder.mostPages:
        list.sort((a, b) => b.pages.length.compareTo(a.pages.length));
        break;
    }
    return list;
  }

  void _open(ScanDocument doc) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => DocumentScreen(documentId: doc.id)));
  }

  void _startScan() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CaptureScreen()));
  }

  Future<void> _onAction(_DocAction action, ScanDocument doc) async {
    switch (action) {
      case _DocAction.open:
        _open(doc);
        break;
      case _DocAction.rename:
        await DocumentActions.rename(context, doc);
        break;
      case _DocAction.exportPdf:
        await DocumentActions.exportPdf(context, doc);
        break;
      case _DocAction.share:
        await DocumentActions.sharePdf(context, doc);
        break;
      case _DocAction.delete:
        await DocumentActions.delete(context, doc);
        break;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset('assets/images/comsats-logo.png'),
        ),
        title: const Text('My Documents'),
        actions: [
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            icon: Icon(_grid ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          PopupMenuButton<SortOrder>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => SortOrder.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startScan,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan'),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (_store.documents.isEmpty) {
            return EmptyState(
              icon: Icons.document_scanner_outlined,
              title: 'No documents yet',
              message:
                  'Scan a page with the camera or import a photo to make your first document.',
              action: FilledButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Start scanning'),
              ),
            );
          }
          final docs = _visible;
          final pageCount =
              _store.documents.fold<int>(0, (sum, d) => sum + d.pages.length);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search documents',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                        '${_store.documents.length} documents  ·  $pageCount pages',
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    Text(_sort.label,
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: docs.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches',
                        message: 'No document name contains "$_query".',
                      )
                    : _grid
                        ? _buildGrid(docs)
                        : _buildList(docs),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<ScanDocument> docs) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final doc = docs[i];
        return Card(
          child: InkWell(
            onTap: () => _open(doc),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _cover(doc)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                  child: Row(
                    children: [
                      Expanded(child: _info(doc)),
                      _menu(doc),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<ScanDocument> docs) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: docs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final doc = docs[i];
        return Card(
          child: InkWell(
            onTap: () => _open(doc),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 56, height: 72, child: _cover(doc)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _info(doc)),
                  _menu(doc),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cover(ScanDocument doc) {
    final path = doc.coverPath;
    if (path == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.insert_drive_file_outlined)),
      );
    }
    return PageThumbnail(path: path);
  }

  Widget _info(ScanDocument doc) {
    final date = DateFormat('d MMM yyyy, h:mm a').format(doc.updatedAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(doc.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 2),
        Text('${doc.pages.length} page${doc.pages.length == 1 ? '' : 's'}  ·  $date',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _menu(ScanDocument doc) {
    return PopupMenuButton<_DocAction>(
      onSelected: (a) => _onAction(a, doc),
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: _DocAction.open,
            child: ListTile(
                leading: Icon(Icons.open_in_new), title: Text('Open'))),
        PopupMenuItem(
            value: _DocAction.rename,
            child: ListTile(
                leading: Icon(Icons.edit_outlined), title: Text('Rename'))),
        PopupMenuItem(
            value: _DocAction.exportPdf,
            child: ListTile(
                leading: Icon(Icons.picture_as_pdf_outlined),
                title: Text('Save as PDF'))),
        PopupMenuItem(
            value: _DocAction.share,
            child: ListTile(
                leading: Icon(Icons.share_outlined), title: Text('Share PDF'))),
        PopupMenuItem(
            value: _DocAction.delete,
            child: ListTile(
                leading: Icon(Icons.delete_outline), title: Text('Delete'))),
      ],
    );
  }
}
