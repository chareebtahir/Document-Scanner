import 'dart:io';

import 'package:flutter/material.dart';

class PageThumbnail extends StatelessWidget {
  final String path;
  final int? number;
  final double cacheWidth;

  const PageThumbnail({
    super.key,
    required this.path,
    this.number,
    this.cacheWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: scheme.surfaceContainerHighest,
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            cacheWidth: cacheWidth.toInt(),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                Icon(Icons.broken_image_outlined, color: scheme.outline),
          ),
        ),
        if (number != null)
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$number',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}
