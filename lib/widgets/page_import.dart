import 'package:flutter/material.dart';

import '../models/scan_page.dart';
import '../services/document_store.dart';
import '../services/image_source_picker.dart';
import 'dialogs.dart';

/// Picks photos from [source] (or asks for one) and turns them into pages.
/// Returns an empty list when nothing was picked.
Future<List<ScanPage>> importPages(BuildContext context,
    {ScanSource? source}) async {
  source ??= await ImageSourcePicker.chooseSource(context);
  if (source == null) return [];

  List<String> paths;
  try {
    paths = await ImageSourcePicker.pick(source);
  } catch (e) {
    if (context.mounted) {
      showError(context,
          'Could not open the ${source == ScanSource.camera ? 'camera' : 'gallery'}. Please allow access and try again.');
    }
    return [];
  }
  if (paths.isEmpty || !context.mounted) return [];

  final pages = await runWithProgress(
    context,
    paths.length == 1
        ? 'Processing page...'
        : 'Processing ${paths.length} pages...',
    () async {
      final result = <ScanPage>[];
      for (final path in paths) {
        result.add(await DocumentStore.instance.importImage(path));
      }
      return result;
    },
  );
  return pages ?? [];
}
