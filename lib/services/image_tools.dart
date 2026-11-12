import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/scan_page.dart';
import 'color_matrix.dart';

/// Image work runs in a background isolate through [compute] so the
/// interface does not freeze while a photo is processed.
class ImageTools {
  /// Smaller copy of the original (at most 1200 px) used while editing.
  static Future<Uint8List> workingCopy(String path) {
    return compute(_workingCopy, path);
  }

  /// Rotated and cropped preview made from a working copy.
  static Future<Uint8List> preview(
      Uint8List working, int quarterTurns, Rect crop) {
    return compute(_preview, [
      working,
      quarterTurns,
      crop.left,
      crop.top,
      crop.right,
      crop.bottom,
    ]);
  }

  /// Full size render of a page with every edit, written to [outPath].
  static Future<void> render(ScanPage page, String outPath, int quality) {
    final matrix =
        ColorMatrix.build(page.filter, page.brightness, page.contrast);
    return compute(_render, [
      page.originalPath,
      outPath,
      page.quarterTurns,
      page.crop.left,
      page.crop.top,
      page.crop.right,
      page.crop.bottom,
      matrix,
      quality,
    ]);
  }
}

img.Image _rotate(img.Image image, int quarterTurns) {
  final turns = quarterTurns % 4;
  if (turns == 0) return image;
  return img.copyRotate(image, angle: 90 * turns);
}

img.Image _crop(img.Image image, double l, double t, double r, double b) {
  if (l <= 0 && t <= 0 && r >= 1 && b >= 1) return image;
  final x = (l * image.width).round();
  final y = (t * image.height).round();
  final w = ((r - l) * image.width).round().clamp(1, image.width - x);
  final h = ((b - t) * image.height).round().clamp(1, image.height - y);
  return img.copyCrop(image, x: x, y: y, width: w, height: h);
}

img.Image _applyMatrix(img.Image image, List<double> m) {
  bool isIdentity = true;
  for (var i = 0; i < 20; i++) {
    if ((m[i] - ColorMatrix.identity[i]).abs() > 0.0001) isIdentity = false;
  }
  if (isIdentity) return image;
  for (final p in image) {
    final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
    p.r = (m[0] * r + m[1] * g + m[2] * b + m[4]).clamp(0, 255);
    p.g = (m[5] * r + m[6] * g + m[7] * b + m[9]).clamp(0, 255);
    p.b = (m[10] * r + m[11] * g + m[12] * b + m[14]).clamp(0, 255);
  }
  return image;
}

img.Image _load(String path) {
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) throw Exception('Could not read this image');
  return img.bakeOrientation(decoded);
}

Uint8List _workingCopy(String path) {
  var image = _load(path);
  if (image.width > 1200 || image.height > 1200) {
    image = image.width >= image.height
        ? img.copyResize(image, width: 1200)
        : img.copyResize(image, height: 1200);
  }
  return img.encodeJpg(image, quality: 90);
}

Uint8List _preview(List<Object> args) {
  var image = img.decodeJpg(args[0] as Uint8List)!;
  image = _rotate(image, args[1] as int);
  image = _crop(image, args[2] as double, args[3] as double,
      args[4] as double, args[5] as double);
  return img.encodeJpg(image, quality: 85);
}

void _render(List<Object> args) {
  var image = _load(args[0] as String);
  image = _rotate(image, args[2] as int);
  image = _crop(image, args[3] as double, args[4] as double,
      args[5] as double, args[6] as double);
  image = _applyMatrix(image, args[7] as List<double>);
  File(args[1] as String)
      .writeAsBytesSync(img.encodeJpg(image, quality: args[8] as int));
}
