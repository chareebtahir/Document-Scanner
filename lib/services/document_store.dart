import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/scan_document.dart';
import '../models/scan_page.dart';
import 'image_tools.dart';
import 'settings_store.dart';

/// Keeps every document on the phone: photos in the app folder and the
/// list of documents in documents.json. There is no server.
class DocumentStore extends ChangeNotifier {
  DocumentStore._();
  static final DocumentStore instance = DocumentStore._();

  final List<ScanDocument> documents = [];
  late Directory _root;
  late Directory _pagesDir;
  late Directory exportsDir;
  int _counter = 0;

  File get _dataFile => File('${_root.path}/documents.json');

  Future<void> load() async {
    _root = await getApplicationDocumentsDirectory();
    _pagesDir = Directory('${_root.path}/pages');
    exportsDir = Directory('${_root.path}/exports');
    await _pagesDir.create(recursive: true);
    await exportsDir.create(recursive: true);

    documents.clear();
    if (await _dataFile.exists()) {
      try {
        final list = jsonDecode(await _dataFile.readAsString()) as List;
        documents.addAll(list.map(
            (d) => ScanDocument.fromJson(d as Map<String, dynamic>)));
      } catch (_) {
        // A damaged file starts an empty library instead of crashing.
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final json = jsonEncode(documents.map((d) => d.toJson()).toList());
    await _dataFile.writeAsString(json);
    notifyListeners();
  }

  String newId() {
    _counter++;
    return '${DateTime.now().microsecondsSinceEpoch}$_counter';
  }

  ScanDocument? byId(String id) {
    for (final d in documents) {
      if (d.id == id) return d;
    }
    return null;
  }

  // Pages

  /// Copies a photo from the camera or gallery into the app folder and
  /// makes its first processed version.
  Future<ScanPage> importImage(String sourcePath) async {
    final id = newId();
    final original = await File(sourcePath).copy('${_pagesDir.path}/$id.jpg');
    final page = ScanPage(
      id: id,
      originalPath: original.path,
      processedPath: original.path,
      filter: SettingsStore.instance.defaultFilter,
    );
    await _renderPage(page);
    return page;
  }

  Future<void> _renderPage(ScanPage page) async {
    final out =
        '${_pagesDir.path}/${page.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await ImageTools.render(
        page, out, SettingsStore.instance.quality.jpegQuality);
    final old = page.processedPath;
    page.processedPath = out;
    if (old != page.originalPath) await _deleteFile(old);
  }

  /// Applies the page settings again after the editor changed them.
  Future<void> updatePage(ScanPage page) async {
    await _renderPage(page);
    for (final d in documents) {
      if (d.pages.contains(page)) d.updatedAt = DateTime.now();
    }
    await _save();
  }

  /// Removes the files of pages that were never saved into a document.
  Future<void> discardPages(List<ScanPage> pages) async {
    for (final p in pages) {
      await _deletePageFiles(p);
    }
  }

  // Documents

  Future<ScanDocument> createDocument(String name, List<ScanPage> pages) async {
    final now = DateTime.now();
    final doc = ScanDocument(
      id: newId(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
      pages: List.of(pages),
    );
    documents.insert(0, doc);
    await _save();
    return doc;
  }

  Future<void> renameDocument(ScanDocument doc, String name) async {
    doc.name = name.trim();
    doc.updatedAt = DateTime.now();
    await _save();
  }

  Future<void> addPages(ScanDocument doc, List<ScanPage> pages) async {
    doc.pages.addAll(pages);
    doc.updatedAt = DateTime.now();
    await _save();
  }

  Future<void> deletePage(ScanDocument doc, ScanPage page) async {
    doc.pages.remove(page);
    doc.updatedAt = DateTime.now();
    await _deletePageFiles(page);
    await _save();
  }

  Future<void> reorderPages(ScanDocument doc, int oldIndex, int newIndex) async {
    final page = doc.pages.removeAt(oldIndex);
    doc.pages.insert(newIndex, page);
    doc.updatedAt = DateTime.now();
    await _save();
  }

  Future<void> deleteDocument(ScanDocument doc) async {
    documents.remove(doc);
    for (final p in doc.pages) {
      await _deletePageFiles(p);
    }
    await _save();
  }

  Future<void> clearAll() async {
    documents.clear();
    if (await _pagesDir.exists()) await _pagesDir.delete(recursive: true);
    if (await exportsDir.exists()) await exportsDir.delete(recursive: true);
    await _pagesDir.create(recursive: true);
    await exportsDir.create(recursive: true);
    await _save();
  }

  /// Returns an error message, or null when [value] is a valid name.
  String? validateName(String? value, {String? exceptId}) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Please enter a name';
    if (name.length < 2) return 'Name must be at least 2 characters';
    if (name.length > 40) return 'Name must be 40 characters or fewer';
    if (RegExp(r'[\\/:*?"<>|]').hasMatch(name)) {
      return 'Name cannot contain \\ / : * ? " < > |';
    }
    final taken = documents.any((d) =>
        d.id != exceptId && d.name.toLowerCase() == name.toLowerCase());
    if (taken) return 'A document with this name already exists';
    return null;
  }

  String suggestName() {
    var index = documents.length + 1;
    while (validateName('Scan $index') != null) {
      index++;
    }
    return 'Scan $index';
  }

  Future<void> _deletePageFiles(ScanPage page) async {
    await _deleteFile(page.originalPath);
    if (page.processedPath != page.originalPath) {
      await _deleteFile(page.processedPath);
    }
  }

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
