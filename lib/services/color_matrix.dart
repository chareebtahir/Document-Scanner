import '../models/scan_page.dart';

/// 4 x 5 colour matrices, the same format Flutter's ColorFilter.matrix uses.
/// The editor previews a page with the matrix, and the saved image is made
/// by applying the same matrix to every pixel, so both look the same.
class ColorMatrix {
  static const List<double> identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  static List<double> saturation(double s) {
    const rw = 0.2126, gw = 0.7152, bw = 0.0722;
    return [
      rw * (1 - s) + s, gw * (1 - s), bw * (1 - s), 0, 0, //
      rw * (1 - s), gw * (1 - s) + s, bw * (1 - s), 0, 0, //
      rw * (1 - s), gw * (1 - s), bw * (1 - s) + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// [brightness] is -0.5 to 0.5, [contrast] is 0.5 to 2.0.
  static List<double> brightnessContrast(double brightness, double contrast) {
    final offset = 128 * (1 - contrast) + brightness * 255;
    return [
      contrast, 0, 0, 0, offset, //
      0, contrast, 0, 0, offset, //
      0, 0, contrast, 0, offset, //
      0, 0, 0, 1, 0, //
    ];
  }

  static List<double> forFilter(PageFilter filter) {
    switch (filter) {
      case PageFilter.original:
        return identity;
      case PageFilter.grayscale:
        return saturation(0);
      case PageFilter.blackWhite:
        return multiply(brightnessContrast(0.1, 2.6), saturation(0));
      case PageFilter.magic:
        return multiply(brightnessContrast(0.04, 1.2), saturation(1.35));
    }
  }

  /// Filter first, then brightness and contrast.
  static List<double> build(
      PageFilter filter, double brightness, double contrast) {
    return multiply(brightnessContrast(brightness, contrast), forFilter(filter));
  }

  /// Returns a matrix that applies [b] first and then [a].
  static List<double> multiply(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + col];
        }
        if (col == 4) sum += a[row * 5 + 4];
        out[row * 5 + col] = sum;
      }
    }
    return out;
  }
}
