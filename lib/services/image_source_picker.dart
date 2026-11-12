import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum ScanSource { camera, gallery }

class ImageSourcePicker {
  static final ImagePicker _picker = ImagePicker();

  /// Bottom sheet that lets the user choose the camera or the gallery.
  static Future<ScanSource?> chooseSource(BuildContext context) {
    return showModalBottomSheet<ScanSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add pages', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.photo_camera)),
                title: const Text('Scan with camera'),
                subtitle: const Text('Take a photo of a paper page'),
                onTap: () => Navigator.pop(context, ScanSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.photo_library)),
                title: const Text('Import from gallery'),
                subtitle: const Text('Choose one or more photos'),
                onTap: () => Navigator.pop(context, ScanSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the paths of the picked photos. An empty list means the user
  /// closed the camera or gallery without choosing anything.
  static Future<List<String>> pick(ScanSource source) async {
    if (source == ScanSource.camera) {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
      );
      return photo == null ? [] : [photo.path];
    }
    final photos = await _picker.pickMultiImage(
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 95,
    );
    return photos.map((p) => p.path).toList();
  }
}
