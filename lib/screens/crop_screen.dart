import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/scan_page.dart';

enum _Handle { topLeft, topRight, bottomLeft, bottomRight, move }

/// Drag the corners (or the middle) of the frame to choose the crop.
/// The crop is stored from 0 to 1 so it does not depend on image size.
class CropScreen extends StatefulWidget {
  final Uint8List image;
  final Rect initialCrop;

  const CropScreen({super.key, required this.image, required this.initialCrop});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  static const double _minSize = 0.1;
  late Rect _crop = widget.initialCrop;
  Size? _imageSize;
  _Handle? _active;

  @override
  void initState() {
    super.initState();
    _readSize();
  }

  Future<void> _readSize() async {
    final codec = await ui.instantiateImageCodec(widget.image);
    final frame = await codec.getNextFrame();
    setState(() => _imageSize = Size(
        frame.image.width.toDouble(), frame.image.height.toDouble()));
  }

  /// Where the image is drawn inside the available space.
  Rect _imageArea(Size box) {
    final fitted = applyBoxFit(BoxFit.contain, _imageSize!, box).destination;
    final left = (box.width - fitted.width) / 2;
    final top = (box.height - fitted.height) / 2;
    return Rect.fromLTWH(left, top, fitted.width, fitted.height);
  }

  Rect _toScreen(Rect area) => Rect.fromLTRB(
        area.left + _crop.left * area.width,
        area.top + _crop.top * area.height,
        area.left + _crop.right * area.width,
        area.top + _crop.bottom * area.height,
      );

  void _onStart(Offset point, Rect area) {
    final frame = _toScreen(area);
    const reach = 36.0;
    final corners = {
      _Handle.topLeft: frame.topLeft,
      _Handle.topRight: frame.topRight,
      _Handle.bottomLeft: frame.bottomLeft,
      _Handle.bottomRight: frame.bottomRight,
    };
    _active = null;
    for (final entry in corners.entries) {
      if ((entry.value - point).distance < reach) _active = entry.key;
    }
    if (_active == null && frame.contains(point)) _active = _Handle.move;
  }

  void _onUpdate(Offset delta, Rect area) {
    if (_active == null) return;
    final dx = delta.dx / area.width;
    final dy = delta.dy / area.height;
    var l = _crop.left, t = _crop.top, r = _crop.right, b = _crop.bottom;

    switch (_active!) {
      case _Handle.topLeft:
        l = (l + dx).clamp(0.0, r - _minSize);
        t = (t + dy).clamp(0.0, b - _minSize);
        break;
      case _Handle.topRight:
        r = (r + dx).clamp(l + _minSize, 1.0);
        t = (t + dy).clamp(0.0, b - _minSize);
        break;
      case _Handle.bottomLeft:
        l = (l + dx).clamp(0.0, r - _minSize);
        b = (b + dy).clamp(t + _minSize, 1.0);
        break;
      case _Handle.bottomRight:
        r = (r + dx).clamp(l + _minSize, 1.0);
        b = (b + dy).clamp(t + _minSize, 1.0);
        break;
      case _Handle.move:
        final w = r - l, h = b - t;
        l = (l + dx).clamp(0.0, 1.0 - w);
        t = (t + dy).clamp(0.0, 1.0 - h);
        r = l + w;
        b = t + h;
        break;
    }
    setState(() => _crop = Rect.fromLTRB(l, t, r, b));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        title: const Text('Crop'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _crop = ScanPage.fullCrop),
            child: const Text('Full page'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _crop),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
      body: _imageSize == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(builder: (context, constraints) {
                final area = _imageArea(constraints.biggest);
                return GestureDetector(
                  onPanStart: (d) => _onStart(d.localPosition, area),
                  onPanUpdate: (d) => _onUpdate(d.delta, area),
                  onPanEnd: (_) => _active = null,
                  child: Stack(
                    children: [
                      Positioned.fromRect(
                        rect: area,
                        child: Image.memory(widget.image, fit: BoxFit.fill),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CropPainter(
                            frame: _toScreen(area),
                            color: Theme.of(context).colorScheme.primaryFixedDim,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Drag a corner to resize. Drag inside the frame to move it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect frame;
  final Color color;

  _CropPainter({required this.frame, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(frame);
    canvas.drawPath(shade, Paint()..color = Colors.black.withValues(alpha: 0.6));

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = frame.left + frame.width * i / 3;
      final y = frame.top + frame.height * i / 3;
      canvas.drawLine(Offset(x, frame.top), Offset(x, frame.bottom), line);
      canvas.drawLine(Offset(frame.left, y), Offset(frame.right, y), line);
    }

    canvas.drawRect(
        frame,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    final handle = Paint()..color = color;
    for (final corner in [
      frame.topLeft,
      frame.topRight,
      frame.bottomLeft,
      frame.bottomRight
    ]) {
      canvas.drawCircle(corner, 10, handle);
      canvas.drawCircle(corner, 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.frame != frame || old.color != color;
}
