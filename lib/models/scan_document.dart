import 'scan_page.dart';

class ScanDocument {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<ScanPage> pages;

  ScanDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
  });

  String? get coverPath => pages.isEmpty ? null : pages.first.processedPath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory ScanDocument.fromJson(Map<String, dynamic> json) => ScanDocument(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        pages: (json['pages'] as List)
            .map((p) => ScanPage.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
