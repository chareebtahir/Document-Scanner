# Document Scanner

A Flutter app for Android that turns paper pages into clean, organised PDF
documents. Mid Lab project, COMSATS University Islamabad, Mobile Application
Development.

**Option 1: 100% frontend.** Everything runs on the phone. There is no backend,
no account, and no internet needed.

## Deliverables (all on D:)

| Item | Path |
| --- | --- |
| Flutter project | `D:\document-scanner` |
| Project report (Word) | `D:\document-scanner\docs\Document-Scanner-Project-Report.docx` |
| Presentation (PowerPoint) | `D:\document-scanner\docs\Document-Scanner-Presentation.pptx` |
| Demo script | `D:\document-scanner\DEMO.md` |
| University logo | `D:\document-scanner\assets\images\comsats-logo.png` |

| Member | Roll no. | Part |
| --- | --- | --- |
| Areeb Tahir | FA23-BCS-468 | Camera, import and document library |
| Sohaib Dost | SP24-BCS-030 | Crop, image processing, PDF, files and sharing |

## Run it

1. Open this folder in Android Studio (with the Flutter and Dart plugins).
2. Start the Pixel_7 emulator from Device Manager, or plug in an Android phone.
3. Run `flutter pub get`, then press Run, or type `flutter run`.

The emulator camera shows a virtual room. To test with real pages, put a few
document photos on the emulator (drag them onto the window) and use Gallery.

## Feature checklist

| # | Feature | Where |
| --- | --- | --- |
| 1 | Splash screen with university logo | `splash_screen.dart` |
| 2 | Three-page introduction, shown once, can be replayed | `onboarding_screen.dart` |
| 3 | Scan a page with the camera | `capture_screen.dart`, `image_source_picker.dart` |
| 4 | Import one or more photos from the gallery | same |
| 5 | Crop with draggable corners | `crop_screen.dart` |
| 6 | Rotate left and right | `edit_page_screen.dart` |
| 7 | Brightness and contrast sliders, live preview | `edit_page_screen.dart`, `color_matrix.dart` |
| 8 | Filters: Original, Grayscale, B & W, Magic | same |
| 9 | Edits are non-destructive and can be reset | `scan_page.dart`, `image_tools.dart` |
| 10 | Multi-page documents, add pages later | `document_screen.dart` |
| 11 | Reorder pages by dragging | `document_screen.dart` |
| 12 | Full-screen page viewer with swipe and zoom | `page_viewer_screen.dart` |
| 13 | Delete a page or a document (with confirmation) | `document_actions.dart` |
| 14 | Rename with validation (empty, length, symbols, duplicate) | `dialogs.dart`, `document_store.dart` |
| 15 | Library: search, sort, grid or list view | `home_screen.dart` |
| 16 | Create PDF (A4, Letter, or fit to image; margins) | `pdf_service.dart` |
| 17 | Share PDF or page images | `pdf_service.dart` |
| 18 | PDF files screen: share or delete saved PDFs | `exports_screen.dart` |
| 19 | Settings: theme, default filter, quality, PDF size, margin | `settings_screen.dart` |
| 20 | Data is kept after closing the app | `document_store.dart` |
| 21 | Empty, loading and error states on every screen | all screens |
| 22 | Light and dark theme | `app_theme.dart` |
| 23 | About screen with team and university | `about_screen.dart` |

OCR was listed as optional in the project brief and is not included.

## How it works

- `lib/models` holds `ScanPage` and `ScanDocument`. A page keeps the original
  photo plus its edit settings (turns, crop, brightness, contrast, filter).
- `lib/services/document_store.dart` saves photos in the app folder and the
  document list in `documents.json`. It is a `ChangeNotifier`, so screens use
  `ListenableBuilder` to redraw when something changes.
- `lib/services/image_tools.dart` uses the `image` package in a background
  isolate (`compute`) to rotate, crop and apply the colour matrix.
- `lib/services/color_matrix.dart` builds one 4 x 5 matrix for the filter,
  brightness and contrast. The editor previews it with `ColorFilter.matrix`,
  and the saved image uses the same numbers, so the preview matches.
- `lib/services/pdf_service.dart` uses the `pdf` package to make one PDF page
  per scanned page.

## Packages

`image_picker`, `image`, `pdf`, `share_plus`, `path_provider`,
`shared_preferences`, `intl`. All of them work offline on the device.
