import 'package:doc_scanner/models/scan_page.dart';
import 'package:doc_scanner/services/color_matrix.dart';
import 'package:doc_scanner/services/document_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ColorMatrix', () {
    test('original filter with no adjustment is the identity', () {
      expect(ColorMatrix.build(PageFilter.original, 0, 1),
          ColorMatrix.identity);
    });

    test('multiply applies the second matrix first', () {
      final gray = ColorMatrix.saturation(0);
      final m = ColorMatrix.multiply(ColorMatrix.identity, gray);
      for (var i = 0; i < 20; i++) {
        expect(m[i], closeTo(gray[i], 1e-9));
      }
    });

    test('brightness adds an offset', () {
      final m = ColorMatrix.brightnessContrast(0.2, 1);
      expect(m[4], closeTo(51, 1e-9));
    });
  });

  test('image package rotates clockwise for a positive angle', () {
    final image = img.Image(width: 2, height: 1);
    image.setPixelRgb(0, 0, 255, 0, 0);
    image.setPixelRgb(1, 0, 0, 0, 255);
    final rotated = img.copyRotate(image, angle: 90);
    expect(rotated.width, 1);
    expect(rotated.height, 2);
    expect(rotated.getPixel(0, 0).r, 255);
  });

  group('Document name validation', () {
    final store = DocumentStore.instance;

    test('rejects empty and too long names', () {
      expect(store.validateName(''), isNotNull);
      expect(store.validateName('   '), isNotNull);
      expect(store.validateName('a' * 41), isNotNull);
    });

    test('rejects characters a file name cannot use', () {
      expect(store.validateName('notes/math'), isNotNull);
      expect(store.validateName('what?'), isNotNull);
    });

    test('accepts a normal name', () {
      expect(store.validateName('Lab report 3'), isNull);
    });
  });
}
