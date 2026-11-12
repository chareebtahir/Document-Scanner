# Document Scanner — viva demo (5 minutes)

Run on **Android emulator or phone only**. Browser demos get zero marks.

## Before the exam

1. Open `D:\document-scanner` in Android Studio (Flutter + Dart plugins).
2. Start Pixel_7 emulator (hypervisor driver already installed) or plug in a phone with USB debugging.
3. Run the app (`flutter run` or the green Run button). A debug APK is also at `build\app\outputs\flutter-apk\app-debug.apk`.
4. If the gallery is empty, drag `docs\sample_pages\page_1.jpg` … `page_3.jpg` onto the emulator window.
5. Turn off Cursor / Copilot / AI autocomplete before the viva (exam rule).

## Demo path

1. **Import** — Scan → Gallery → pick the three sample pages.
2. **Edit** — open page 1 → Crop to the paper → Filters → B & W → Adjust contrast → Done.
3. **Save** — tap Save → try empty name (show validation) → enter `Lab Report 3`.
4. **Reorder** — Document → reorder → drag page 3 to the top → open viewer and pinch zoom.
5. **PDF** — tap PDF → open **PDF files** tab → Share.

## Deliverables on D:

| Item | Path |
| --- | --- |
| Flutter app | `D:\document-scanner` |
| Project report | `D:\document-scanner\docs\Document-Scanner-Project-Report.docx` |
| Presentation | `D:\document-scanner\docs\Document-Scanner-Presentation.pptx` |
| Feature checklist | `D:\document-scanner\README.md` |

## Option 1 note

This is **100% frontend**. No backend. All processing is on the phone. OCR was optional and is not included.
