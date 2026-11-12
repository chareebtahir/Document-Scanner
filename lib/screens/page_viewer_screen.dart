import 'dart:io';

import 'package:flutter/material.dart';

import '../services/document_store.dart';
import '../services/pdf_service.dart';
import '../services/settings_store.dart';
import '../widgets/dialogs.dart';
import 'edit_page_screen.dart';

/// Full screen pages. Swipe to move between pages, pinch to zoom.
class PageViewerScreen extends StatefulWidget {
  final String documentId;
  final int initialIndex;

  const PageViewerScreen(
      {super.key, required this.documentId, required this.initialIndex});

  @override
  State<PageViewerScreen> createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  final _store = DocumentStore.instance;
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final doc = _store.byId(widget.documentId);
        if (doc == null || doc.pages.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return const Scaffold(backgroundColor: Colors.black);
        }
        if (_index >= doc.pages.length) _index = doc.pages.length - 1;
        final page = doc.pages[_index];

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            titleTextStyle: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            title: Text('Page ${_index + 1} of ${doc.pages.length}'),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditPageScreen(page: page))),
              ),
              IconButton(
                tooltip: 'Share page',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => PdfService.share([page.processedPath]),
              ),
              IconButton(
                tooltip: 'Delete page',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (SettingsStore.instance.confirmDelete) {
                    final ok = await confirmAction(context,
                        title: 'Delete page ${_index + 1}?',
                        message: 'This page will be removed from "${doc.name}".');
                    if (!ok) return;
                  }
                  await _store.deletePage(doc, page);
                },
              ),
            ],
          ),
          body: PageView.builder(
            controller: _controller,
            itemCount: doc.pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.file(
                  File(doc.pages[i].processedPath),
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Pinch to zoom  ·  Swipe for the next page',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            ),
          ),
        );
      },
    );
  }
}
