import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/scan_page.dart';
import '../services/color_matrix.dart';
import '../services/document_store.dart';
import '../services/image_tools.dart';
import '../widgets/dialogs.dart';
import 'crop_screen.dart';

enum _Panel { none, adjust, filter }

/// Crop, rotate, brightness, contrast and filter for one page.
/// Returns true when the page was changed and saved.
class EditPageScreen extends StatefulWidget {
  final ScanPage page;
  const EditPageScreen({super.key, required this.page});

  @override
  State<EditPageScreen> createState() => _EditPageScreenState();
}

class _EditPageScreenState extends State<EditPageScreen> {
  late int _turns = widget.page.quarterTurns;
  late Rect _crop = widget.page.crop;
  late double _brightness = widget.page.brightness;
  late double _contrast = widget.page.contrast;
  late PageFilter _filter = widget.page.filter;

  Uint8List? _working;
  Uint8List? _preview;
  bool _loading = true;
  String? _error;
  _Panel _panel = _Panel.none;

  bool get _changed =>
      _turns != widget.page.quarterTurns ||
      _crop != widget.page.crop ||
      _brightness != widget.page.brightness ||
      _contrast != widget.page.contrast ||
      _filter != widget.page.filter;

  List<double> get _matrix => ColorMatrix.build(_filter, _brightness, _contrast);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _working = await ImageTools.workingCopy(widget.page.originalPath);
      await _refreshPreview();
    } catch (e) {
      setState(() {
        _error = 'This image could not be opened.';
        _loading = false;
      });
    }
  }

  Future<void> _refreshPreview() async {
    setState(() => _loading = true);
    final bytes = await ImageTools.preview(_working!, _turns, _crop);
    if (!mounted) return;
    setState(() {
      _preview = bytes;
      _loading = false;
    });
  }

  void _rotate(bool clockwise) {
    final c = _crop;
    setState(() {
      if (clockwise) {
        _turns = (_turns + 1) % 4;
        _crop = Rect.fromLTRB(1 - c.bottom, c.left, 1 - c.top, c.right);
      } else {
        _turns = (_turns + 3) % 4;
        _crop = Rect.fromLTRB(c.top, 1 - c.right, c.bottom, 1 - c.left);
      }
    });
    _refreshPreview();
  }

  Future<void> _openCrop() async {
    setState(() => _loading = true);
    final rotated =
        await ImageTools.preview(_working!, _turns, ScanPage.fullCrop);
    if (!mounted) return;
    setState(() => _loading = false);
    final result = await Navigator.push<Rect>(
      context,
      MaterialPageRoute(
          builder: (_) => CropScreen(image: rotated, initialCrop: _crop)),
    );
    if (result != null && result != _crop) {
      _crop = result;
      _refreshPreview();
    }
  }

  void _reset() {
    setState(() {
      _turns = 0;
      _crop = ScanPage.fullCrop;
      _brightness = 0;
      _contrast = 1;
      _filter = PageFilter.original;
    });
    _refreshPreview();
  }

  Future<void> _save() async {
    if (!_changed) {
      Navigator.pop(context, false);
      return;
    }
    final page = widget.page;
    final saved = await runWithProgress(context, 'Saving page...', () async {
      page.quarterTurns = _turns;
      page.crop = _crop;
      page.brightness = _brightness;
      page.contrast = _contrast;
      page.filter = _filter;
      await DocumentStore.instance.updatePage(page);
      return true;
    });
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _onBack() async {
    final discard = await confirmAction(context,
        title: 'Discard changes?',
        message: 'Your edits to this page will be lost.',
        confirmLabel: 'Discard');
    if (discard && mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF15161A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF15161A),
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          title: const Text('Edit page'),
          actions: [
            TextButton(
              onPressed: _working == null ? null : _reset,
              child: const Text('Reset'),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _working == null ? null : _save,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildPreview()),
            if (_panel == _Panel.adjust) _buildAdjustPanel(),
            if (_panel == _Panel.filter) _buildFilterPanel(),
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.white)));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_preview != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_matrix),
              child: Image.memory(_preview!, gaplessPlayback: true),
            ),
          ),
        if (_loading) const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildAdjustPanel() {
    return Container(
      color: const Color(0xFF1F2026),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          _slider(
            icon: Icons.brightness_6_outlined,
            label: 'Brightness',
            value: _brightness,
            min: -0.5,
            max: 0.5,
            display: '${(_brightness * 200).round()}',
            onChanged: (v) => setState(() => _brightness = v),
          ),
          _slider(
            icon: Icons.contrast,
            label: 'Contrast',
            value: _contrast,
            min: 0.5,
            max: 2.0,
            display: '${(_contrast * 100).round()}%',
            onChanged: (v) => setState(() => _contrast = v),
          ),
        ],
      ),
    );
  }

  Widget _slider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(
          width: 44,
          child: Text(display,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: const Color(0xFF1F2026),
      height: 128,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        children: PageFilter.values.map((f) {
          final selected = f == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _preview == null
                        ? const SizedBox()
                        : ColorFiltered(
                            colorFilter: ColorFilter.matrix(ColorMatrix.build(
                                f, _brightness, _contrast)),
                            child: Image.memory(_preview!,
                                fit: BoxFit.cover,
                                cacheWidth: 160,
                                gaplessPlayback: true),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(f.label,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.normal)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolbar() {
    final enabled = _working != null && !_loading;
    Widget tool(IconData icon, String label, VoidCallback onTap,
        {bool active = false}) {
      final color = active
          ? Theme.of(context).colorScheme.primaryFixedDim
          : Colors.white;
      return Expanded(
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: enabled ? color : Colors.white30),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: enabled ? color : Colors.white30, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    void toggle(_Panel p) =>
        setState(() => _panel = _panel == p ? _Panel.none : p);

    return Container(
      color: const Color(0xFF15161A),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            tool(Icons.crop, 'Crop', _openCrop),
            tool(Icons.rotate_left, 'Left', () => _rotate(false)),
            tool(Icons.rotate_right, 'Right', () => _rotate(true)),
            tool(Icons.tune, 'Adjust', () => toggle(_Panel.adjust),
                active: _panel == _Panel.adjust),
            tool(Icons.filter_b_and_w, 'Filters', () => toggle(_Panel.filter),
                active: _panel == _Panel.filter),
          ],
        ),
      ),
    );
  }
}
