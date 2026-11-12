import 'dart:ui';

enum PageFilter { original, grayscale, blackWhite, magic }

extension PageFilterLabel on PageFilter {
  String get label {
    switch (this) {
      case PageFilter.original:
        return 'Original';
      case PageFilter.grayscale:
        return 'Grayscale';
      case PageFilter.blackWhite:
        return 'B & W';
      case PageFilter.magic:
        return 'Magic';
    }
  }
}

/// One scanned page. The original photo is never changed; every edit is
/// stored as a setting and applied again to make [processedPath].
class ScanPage {
  final String id;
  final String originalPath;
  String processedPath;
  int quarterTurns;
  Rect crop;
  double brightness;
  double contrast;
  PageFilter filter;

  ScanPage({
    required this.id,
    required this.originalPath,
    required this.processedPath,
    this.quarterTurns = 0,
    this.crop = fullCrop,
    this.brightness = 0,
    this.contrast = 1,
    this.filter = PageFilter.original,
  });

  static const Rect fullCrop = Rect.fromLTRB(0, 0, 1, 1);

  bool get isEdited =>
      quarterTurns != 0 ||
      crop != fullCrop ||
      brightness != 0 ||
      contrast != 1 ||
      filter != PageFilter.original;

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalPath': originalPath,
        'processedPath': processedPath,
        'quarterTurns': quarterTurns,
        'crop': [crop.left, crop.top, crop.right, crop.bottom],
        'brightness': brightness,
        'contrast': contrast,
        'filter': filter.name,
      };

  factory ScanPage.fromJson(Map<String, dynamic> json) {
    final c = (json['crop'] as List).cast<num>();
    return ScanPage(
      id: json['id'],
      originalPath: json['originalPath'],
      processedPath: json['processedPath'],
      quarterTurns: json['quarterTurns'] ?? 0,
      crop: Rect.fromLTRB(c[0].toDouble(), c[1].toDouble(), c[2].toDouble(),
          c[3].toDouble()),
      brightness: (json['brightness'] as num).toDouble(),
      contrast: (json['contrast'] as num).toDouble(),
      filter: PageFilter.values.byName(json['filter']),
    );
  }
}
