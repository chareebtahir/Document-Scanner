import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan_document.dart';
import '../services/document_store.dart';
import '../services/pdf_service.dart';
import '../services/settings_store.dart';
import 'dialogs.dart';

/// Actions used by both the library and the document screen.
class DocumentActions {
  static Future<void> rename(BuildContext context, ScanDocument doc) async {
    final name = await showNameDialog(context,
        title: 'Rename document', initial: doc.name, exceptId: doc.id);
    if (name == null || name == doc.name) return;
    await DocumentStore.instance.renameDocument(doc, name);
    if (context.mounted) showMessage(context, 'Renamed to "$name"');
  }

  /// Returns true when the document was deleted.
  static Future<bool> delete(BuildContext context, ScanDocument doc) async {
    if (SettingsStore.instance.confirmDelete) {
      final ok = await confirmAction(context,
          title: 'Delete document?',
          message:
              '"${doc.name}" and its ${doc.pages.length} page(s) will be removed from this phone.');
      if (!ok) return false;
    }
    await DocumentStore.instance.deleteDocument(doc);
    if (context.mounted) showMessage(context, '"${doc.name}" deleted');
    return true;
  }

  static Future<File?> exportPdf(BuildContext context, ScanDocument doc) async {
    if (doc.pages.isEmpty) {
      showError(context, 'Add at least one page before making a PDF');
      return null;
    }
    final file = await runWithProgress(
        context, 'Creating PDF...', () => PdfService.export(doc));
    if (file != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Saved ${PdfService.fileNameFor(doc)}'),
          action: SnackBarAction(
              label: 'Share', onPressed: () => PdfService.share([file.path])),
        ));
    }
    return file;
  }

  static Future<void> sharePdf(BuildContext context, ScanDocument doc) async {
    if (doc.pages.isEmpty) {
      showError(context, 'Add at least one page before sharing');
      return;
    }
    final file = await runWithProgress(
        context, 'Preparing PDF...', () => PdfService.export(doc));
    if (file != null) await PdfService.share([file.path], text: doc.name);
  }

  static Future<void> shareImages(BuildContext context, ScanDocument doc) async {
    if (doc.pages.isEmpty) {
      showError(context, 'This document has no pages');
      return;
    }
    await PdfService.share(doc.pages.map((p) => p.processedPath).toList(),
        text: doc.name);
  }
}
