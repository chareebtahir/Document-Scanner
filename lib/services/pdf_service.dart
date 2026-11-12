import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/scan_document.dart';
import 'document_store.dart';
import 'settings_store.dart';

class PdfService {
  static String fileNameFor(ScanDocument doc) =>
      '${doc.name.replaceAll(RegExp(r'\s+'), '_')}.pdf';

  /// Builds one PDF page per scanned page and saves it in the exports folder.
  static Future<File> export(ScanDocument doc) async {
    if (doc.pages.isEmpty) throw Exception('This document has no pages');
    final settings = SettingsStore.instance;
    final pdf = pw.Document(title: doc.name, creator: 'Document Scanner');

    for (final page in doc.pages) {
      final image = pw.MemoryImage(await File(page.processedPath).readAsBytes());
      final margin = settings.margin.points;
      PdfPageFormat format;
      switch (settings.pageSize) {
        case PdfPageSize.a4:
          format = PdfPageFormat.a4;
          break;
        case PdfPageSize.letter:
          format = PdfPageFormat.letter;
          break;
        case PdfPageSize.fitImage:
          final width = PdfPageFormat.a4.width;
          final ratio = (image.height ?? 1) / (image.width ?? 1);
          format = PdfPageFormat(width, (width - margin * 2) * ratio + margin * 2);
          break;
      }
      pdf.addPage(pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.all(margin),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ));
    }

    final file =
        File('${DocumentStore.instance.exportsDir.path}/${fileNameFor(doc)}');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<List<File>> listExports() async {
    final dir = DocumentStore.instance.exportsDir;
    if (!await dir.exists()) return [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.pdf'))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  static Future<void> share(List<String> paths, {String? text}) async {
    await SharePlus.instance.share(ShareParams(
      files: paths.map((p) => XFile(p)).toList(),
      text: text,
    ));
  }
}
