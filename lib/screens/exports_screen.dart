import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/pdf_service.dart';
import '../services/settings_store.dart';
import '../widgets/dialogs.dart';
import '../widgets/empty_state.dart';

/// Lists the PDF files saved on this phone.
class ExportsScreen extends StatefulWidget {
  const ExportsScreen({super.key});

  @override
  State<ExportsScreen> createState() => _ExportsScreenState();
}

class _ExportsScreenState extends State<ExportsScreen> {
  late Future<List<File>> _files = PdfService.listExports();

  Future<void> _reload() async {
    final next = PdfService.listExports();
    setState(() {
      _files = next;
    });
    await next;
  }

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _name(File f) => f.uri.pathSegments.last;

  Future<void> _delete(File file) async {
    if (SettingsStore.instance.confirmDelete) {
      final ok = await confirmAction(context,
          title: 'Delete PDF?',
          message:
              '"${_name(file)}" will be deleted. The scanned document stays in your library.');
      if (!ok) return;
    }
    await file.delete();
    if (mounted) showMessage(context, 'PDF deleted');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF files'),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              onPressed: _reload,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<File>>(
        future: _files,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Could not read files',
              message: 'Please try again.',
            );
          }
          final files = snapshot.data!;
          if (files.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'No PDF files yet',
                  message:
                      'Open a document and tap PDF. Your saved files will appear here.',
                ),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: files.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final file = files[i];
                final stat = file.statSync();
                final date =
                    DateFormat('d MMM yyyy, h:mm a').format(stat.modified);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      child: Icon(Icons.picture_as_pdf,
                          color: Theme.of(context).colorScheme.error),
                    ),
                    title: Text(_name(file),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${_size(stat.size)}  ·  $date'),
                    onTap: () => PdfService.share([file.path]),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'share') PdfService.share([file.path]);
                        if (v == 'delete') _delete(file);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'share',
                            child: ListTile(
                                leading: Icon(Icons.share_outlined),
                                title: Text('Share or open'))),
                        PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'))),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
