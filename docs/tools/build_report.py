"""Builds the project report (Word) for the Document Scanner app."""
import os

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DOCS = os.path.join(ROOT, "docs")
SHOTS = os.path.join(DOCS, "screenshots")
LOGO = os.path.join(ROOT, "assets", "images", "comsats-logo.png")
OUT = os.path.join(DOCS, "Document-Scanner-Project-Report.docx")

PURPLE = RGBColor(0x4A, 0x2C, 0x7F)
BLUE = RGBColor(0x1A, 0x5D, 0xAB)
INK = RGBColor(0x1E, 0x22, 0x2B)
MUTED = RGBColor(0x5A, 0x60, 0x6E)

MEMBERS = [
    ("Areeb Tahir", "FA23-BCS-468", "Camera and gallery import, capture screen, document library (search, sort, grid and list), splash and introduction"),
    ("Sohaib Dost", "SP24-BCS-030", "Crop screen, rotate, brightness, contrast and filters, multi-page PDF, PDF files screen, sharing, settings"),
]

FEATURES = [
    ("Splash screen with university logo", "Splash"),
    ("Three-page introduction, shown once, can be replayed from Settings", "Introduction"),
    ("Scan a page with the camera", "New scan"),
    ("Import one or more photos from the gallery", "New scan"),
    ("Crop with draggable corners and a movable frame", "Crop"),
    ("Rotate left and right", "Edit page"),
    ("Brightness and contrast sliders with live preview", "Edit page"),
    ("Filters: Original, Grayscale, B & W, Magic", "Edit page"),
    ("Edits are non-destructive and can be reset", "Edit page"),
    ("Multi-page documents; add pages later", "Document"),
    ("Reorder pages by dragging", "Document"),
    ("Full-screen page viewer with swipe and pinch zoom", "Page viewer"),
    ("Delete a page or a whole document, with confirmation", "Document, Viewer"),
    ("Rename with validation (empty, length, symbols, duplicate)", "Dialogs"),
    ("Library with search, sort and grid or list view", "My Documents"),
    ("Create PDF (A4, Letter or fit to image, with margins)", "Document"),
    ("Share the PDF or the page images", "Document, Viewer"),
    ("PDF files screen: share or delete saved PDFs", "PDF files"),
    ("Settings: theme, default filter, quality, PDF size, margin", "Settings"),
    ("Data is kept after the app is closed", "All"),
    ("Empty, loading and error states", "All"),
    ("Light and dark theme", "All"),
    ("About screen with team and university", "About"),
]


def shade(cell, hex_color):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_color)
    tc_pr.append(shd)


def set_font(run, size=11, bold=False, color=INK, italic=False, font="Calibri"):
    run.font.name = font
    run._element.rPr.rFonts.set(qn("w:eastAsia"), font)
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color


def para(doc, text="", size=11, bold=False, color=INK, align=None, after=6, before=0, italic=False):
    p = doc.add_paragraph()
    if text:
        set_font(p.add_run(text), size, bold, color, italic)
    p.paragraph_format.space_after = Pt(after)
    p.paragraph_format.space_before = Pt(before)
    if align:
        p.alignment = align
    return p


def heading(doc, text, level=1):
    h = doc.add_heading(level=level)
    run = h.add_run(text)
    set_font(run, 18 if level == 1 else 13.5, True, PURPLE if level == 1 else BLUE, font="Cambria")
    h.paragraph_format.space_before = Pt(18 if level == 1 else 10)
    h.paragraph_format.space_after = Pt(6)
    return h


def bullets(doc, items):
    for item in items:
        p = doc.add_paragraph(style="List Bullet")
        set_font(p.add_run(item), 11)
        p.paragraph_format.space_after = Pt(2)


def table(doc, header, rows, widths):
    t = doc.add_table(rows=1, cols=len(header))
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, text in enumerate(header):
        cell = t.rows[0].cells[i]
        cell.text = ""
        set_font(cell.paragraphs[0].add_run(text), 10.5, True, RGBColor(255, 255, 255))
        shade(cell, "4A2C7F")
    for r, row in enumerate(rows):
        cells = t.add_row().cells
        for i, text in enumerate(row):
            cells[i].text = ""
            set_font(cells[i].paragraphs[0].add_run(str(text)), 10)
            if r % 2 == 1:
                shade(cells[i], "F1EEF7")
    for row in t.rows:
        for i, w in enumerate(widths):
            row.cells[i].width = Cm(w)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)
    return t


def figure(doc, name, caption, width=5.2):
    path = os.path.join(SHOTS, name)
    if not os.path.exists(path):
        return
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run().add_picture(path, width=Cm(width))
    cap = para(doc, caption, 9.5, color=MUTED, align=WD_ALIGN_PARAGRAPH.CENTER, after=10, italic=True)
    return cap


def figure_row(doc, items, width=4.6):
    """Two or three screenshots side by side in a borderless table."""
    items = [i for i in items if os.path.exists(os.path.join(SHOTS, i[0]))]
    if not items:
        return
    t = doc.add_table(rows=2, cols=len(items))
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, (name, caption) in enumerate(items):
        img_p = t.rows[0].cells[i].paragraphs[0]
        img_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        img_p.add_run().add_picture(os.path.join(SHOTS, name), width=Cm(width))
        cap_p = t.rows[1].cells[i].paragraphs[0]
        cap_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        set_font(cap_p.add_run(caption), 9.5, color=MUTED, italic=True)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)


def code(doc, text):
    for line in text.strip("\n").split("\n"):
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.left_indent = Cm(0.5)
        set_font(p.add_run(line if line else " "), 9, color=RGBColor(0x2B, 0x2B, 0x40), font="Consolas")
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def page_number_footer(section):
    p = section.footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    set_font(p.add_run("Document Scanner  ·  COMSATS University Islamabad  ·  Page "), 9, color=MUTED)
    run = p.add_run()
    for kind, text in (("begin", None), (None, "PAGE"), ("end", None)):
        if kind:
            el = OxmlElement("w:fldChar")
            el.set(qn("w:fldCharType"), kind)
        else:
            el = OxmlElement("w:instrText")
            el.set(qn("xml:space"), "preserve")
            el.text = text
        run._r.append(el)
    set_font(run, 9, color=MUTED)


def build():
    doc = Document()
    sec = doc.sections[0]
    sec.page_width, sec.page_height = Cm(21), Cm(29.7)
    for side in ("left_margin", "right_margin"):
        setattr(sec, side, Cm(2.3))
    sec.top_margin = Cm(2)
    sec.bottom_margin = Cm(2)
    doc.styles["Normal"].font.name = "Calibri"
    doc.styles["Normal"].font.size = Pt(11)

    # Title page
    para(doc, "", after=30)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.add_run().add_picture(LOGO, width=Cm(4.6))
    para(doc, "COMSATS UNIVERSITY ISLAMABAD", 18, True, PURPLE, WD_ALIGN_PARAGRAPH.CENTER, after=2, before=10)
    para(doc, "Department of Computer Science", 12, color=MUTED, align=WD_ALIGN_PARAGRAPH.CENTER, after=30)
    para(doc, "Mobile Application Development", 14, True, BLUE, WD_ALIGN_PARAGRAPH.CENTER, after=4)
    para(doc, "Mid Lab Assessment  ·  Project Report", 12, color=MUTED, align=WD_ALIGN_PARAGRAPH.CENTER, after=26)
    title = para(doc, "Document Scanner", 34, True, INK, WD_ALIGN_PARAGRAPH.CENTER, after=4)
    title.runs[0].font.name = "Cambria"
    para(doc, "Paper pages to clean, organised PDF documents on Android", 13, color=MUTED, align=WD_ALIGN_PARAGRAPH.CENTER, after=6)
    para(doc, "Flutter (Dart)  ·  Option 1: 100% Frontend", 12, True, BLUE, WD_ALIGN_PARAGRAPH.CENTER, after=36)

    t = doc.add_table(rows=1, cols=2)
    t.style = "Table Grid"
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, text in enumerate(("Group member", "Registration no.")):
        cell = t.rows[0].cells[i]
        cell.text = ""
        set_font(cell.paragraphs[0].add_run(text), 11, True, RGBColor(255, 255, 255))
        shade(cell, "4A2C7F")
    for name, roll, _ in MEMBERS:
        cells = t.add_row().cells
        cells[0].text, cells[1].text = "", ""
        set_font(cells[0].paragraphs[0].add_run(name), 11.5, True)
        set_font(cells[1].paragraphs[0].add_run(roll), 11.5)
    for row in t.rows:
        row.cells[0].width, row.cells[1].width = Cm(6.5), Cm(5)
    para(doc, "", after=24)
    para(doc, "Submitted to: ______________________", 12, align=WD_ALIGN_PARAGRAPH.CENTER, after=4)
    para(doc, "Date: 12 November 2026   ·   CLAB 10, B Block", 12, align=WD_ALIGN_PARAGRAPH.CENTER)

    body = doc.add_section(WD_SECTION.NEW_PAGE)
    page_number_footer(body)

    # Contents
    heading(doc, "Contents")
    for line in [
        "1. Introduction", "2. Problem statement", "3. Objectives", "4. Project scope",
        "5. Feature checklist and completion", "6. Tools and technologies",
        "7. System design", "8. Screens and user flow", "9. Key implementation details",
        "10. Input validation and screen states", "11. Testing",
        "12. Work division", "13. Limitations and future work", "14. Conclusion",
        "Appendix A: How to run the project", "Appendix B: Project structure",
    ]:
        para(doc, line, 11.5, after=3)
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

    heading(doc, "1. Introduction")
    para(doc, "Students and office workers handle paper every day: lab reports, fee challans, notes, receipts and forms. Sending a clear copy usually means finding a scanner, or sending a crooked, dark phone photo. Document Scanner is an Android app built with Flutter that turns phone photos of paper into clean pages and then into a single multi-page PDF that can be saved and shared.")
    para(doc, "The whole app runs on the phone. It needs no account, no internet connection and no server. Photos, edits and PDF files are kept in the app's private storage, so the documents stay on the device.")

    heading(doc, "2. Problem statement")
    para(doc, "A raw phone photo of a page has four common problems:")
    bullets(doc, [
        "It includes the desk or background around the page.",
        "It is often sideways or upside down.",
        "Room light makes it too dark, too bright or low in contrast.",
        "Several photos of one document are separate files, out of order, and not easy to send as one file.",
    ])
    para(doc, "The app solves each one with a matching tool: crop, rotate, brightness and contrast with scan filters, and a multi-page document that can be reordered and exported as one PDF.")

    heading(doc, "3. Objectives")
    bullets(doc, [
        "Capture pages with the camera or import them from the gallery.",
        "Give simple, reliable editing tools: crop, rotate, brightness, contrast and filters.",
        "Group pages into named documents, with page reordering.",
        "Create a PDF from a document and share it with any installed app.",
        "Keep everything offline and saved between app launches.",
        "Handle every input and state clearly: validation, empty lists, loading and errors.",
    ])

    heading(doc, "4. Project scope")
    para(doc, "The group chose Option 1 of the Mid Lab assessment: a 100% complete frontend. Every planned screen, component and navigation flow is implemented and connected. No backend is part of this project, and the app does not depend on one; all data processing happens on the device.")
    para(doc, "On-device OCR (text recognition) was listed as optional in the project brief. It is not included in this version and is described under future work.")

    heading(doc, "5. Feature checklist and completion")
    para(doc, "Completion is measured as described in the assessment instructions: accepted features divided by all approved features, each with equal weight.")
    table(doc, ["#", "Feature", "Screen", "Status"],
          [(i + 1, f, s, "Complete") for i, (f, s) in enumerate(FEATURES)],
          [1.0, 9.4, 3.6, 2.2])
    para(doc, f"Completion = {len(FEATURES)} / {len(FEATURES)} x 100 = 100%", 12, True, BLUE, after=8)

    heading(doc, "6. Tools and technologies")
    table(doc, ["Tool or package", "Used for"], [
        ("Flutter 3.47 and Dart 3.13", "Cross-platform UI framework and language"),
        ("Android Studio, Pixel 7 emulator", "Development, running and debugging on Android"),
        ("Material 3", "Design system: navigation bar, cards, dialogs, sliders"),
        ("image_picker", "Opens the camera and the gallery (single and multiple photos)"),
        ("image", "Pure Dart image processing: rotate, crop, pixel colour changes"),
        ("pdf", "Creates the multi-page PDF file"),
        ("share_plus", "Opens the Android share sheet for PDFs and images"),
        ("path_provider", "Finds the app's private documents folder"),
        ("shared_preferences", "Stores settings such as theme and PDF size"),
        ("intl", "Formats dates in the library and file lists"),
        ("Git and GitHub", "One shared repository for the group"),
    ], [5.5, 10.7])

    heading(doc, "7. System design")
    heading(doc, "7.1 Architecture", 2)
    para(doc, "The code is split into four layers so each part has one job:")
    table(doc, ["Layer", "Folder", "Responsibility"], [
        ("Models", "lib/models", "ScanPage and ScanDocument classes, with toJson and fromJson"),
        ("Services", "lib/services", "Saving and loading data, image processing, PDF creation, settings"),
        ("Widgets", "lib/widgets", "Reusable pieces: dialogs, empty state, page thumbnail, shared actions"),
        ("Screens", "lib/screens", "One file per screen; they read from the services and draw the UI"),
    ], [2.6, 3.0, 10.6])
    para(doc, "State management uses Flutter's built-in ChangeNotifier. DocumentStore and SettingsStore are single shared objects. When they change they call notifyListeners(), and screens wrapped in ListenableBuilder redraw automatically. Short-lived screen state, such as the current slider value, uses setState.")

    heading(doc, "7.2 Data model", 2)
    para(doc, "A page never overwrites its original photo. Instead it stores the edit settings, and the processed image is made again from the original whenever the settings change. This is called non-destructive editing, and it is why Reset can always return to the original.")
    table(doc, ["ScanPage field", "Type", "Meaning"], [
        ("id", "String", "Unique id, based on the time in microseconds"),
        ("originalPath", "String", "The photo exactly as it was imported"),
        ("processedPath", "String", "The edited image that is shown and put in the PDF"),
        ("quarterTurns", "int (0 to 3)", "Clockwise rotation in steps of 90 degrees"),
        ("crop", "Rect (0 to 1)", "Crop area as fractions of width and height"),
        ("brightness", "double (-0.5 to 0.5)", "Added to every colour value"),
        ("contrast", "double (0.5 to 2.0)", "Stretches colours away from the middle grey"),
        ("filter", "PageFilter", "original, grayscale, blackWhite or magic"),
    ], [3.4, 3.6, 9.2])
    para(doc, "A ScanDocument has an id, a name, created and updated dates, and an ordered list of pages. The list of documents is saved as documents.json in the app folder; photos are saved in a pages folder and PDFs in an exports folder.")

    heading(doc, "7.3 Navigation", 2)
    para(doc, "Splash  →  Introduction (first launch only)  →  Main shell with three tabs: My Documents, PDF files and Settings.")
    bullets(doc, [
        "My Documents  →  New scan  →  Edit page  →  Crop",
        "New scan  →  Save (name dialog)  →  Document",
        "My Documents  →  Document  →  Page viewer  →  Edit page",
        "Document  →  Add pages, Reorder, Create PDF, Share",
        "Settings  →  About, Introduction again, Delete all data",
    ])
    para(doc, "Navigation uses Navigator.push and pushReplacement with MaterialPageRoute. Screens that can lose work (New scan and Edit page) use PopScope to ask before going back.")

    heading(doc, "8. Screens and user flow")
    heading(doc, "8.1 Splash and introduction", 2)
    para(doc, "The splash screen shows the app name and the COMSATS logo on a gradient in the university's purple and blue, then fades into the app. On first launch a three-page introduction explains capture, editing and PDF export; it can be skipped and replayed from Settings.")
    figure_row(doc, [("01_splash.png", "Splash screen"), ("02_onboarding.png", "Introduction"), ("03_home_empty.png", "Empty library")])
    heading(doc, "8.2 New scan", 2)
    para(doc, "The New scan screen collects pages before they become a document. Camera opens the phone camera; Gallery allows several photos at once. Each page can be tapped to edit or removed with its close button. Save asks for a document name.")
    figure_row(doc, [("04_capture.png", "New scan with pages"), ("05_save_dialog.png", "Name dialog")])
    heading(doc, "8.3 Edit page and crop", 2)
    para(doc, "The editor shows a live preview and a toolbar with Crop, Rotate left, Rotate right, Adjust and Filters. Adjust opens brightness and contrast sliders; Filters shows a thumbnail of each filter. The crop screen has a frame with four corner handles and a rule-of-thirds grid; dragging inside the frame moves it.")
    figure_row(doc, [("06_crop.png", "Crop"), ("07_edit_filters.png", "Filters"), ("08_edit_adjust.png", "Brightness and contrast")])
    heading(doc, "8.4 Document, reorder and viewer", 2)
    para(doc, "A document shows its pages in a numbered grid with buttons to add pages, create a PDF and share. The reorder mode turns the grid into a list with drag handles. Tapping a page opens a full-screen viewer with swipe between pages and pinch to zoom.")
    figure_row(doc, [("09_document.png", "Document"), ("10_reorder.png", "Reorder pages"), ("11_viewer.png", "Page viewer")])
    heading(doc, "8.5 Library, PDF files and settings", 2)
    para(doc, "My Documents lists every document with its first page, page count and date. It has search, four sort orders, and a grid or list view. PDF files lists exported PDFs with size and date. Settings controls the theme, default filter, image quality, PDF page size and margin.")
    figure_row(doc, [("12_home.png", "My Documents"), ("13_pdf_files.png", "PDF files"), ("14_settings.png", "Settings")])
    figure_row(doc, [("15_share.png", "Share PDF"), ("16_about.png", "About"), ("17_dark.png", "Dark theme")])

    heading(doc, "9. Key implementation details")
    heading(doc, "9.1 One colour matrix for preview and output", 2)
    para(doc, "Filters, brightness and contrast are combined into one 4 x 5 colour matrix, the same format as Flutter's ColorFilter.matrix. The editor wraps the preview in ColorFiltered, which the GPU applies instantly while a slider moves. When the user taps Done, the same numbers are applied to every pixel of the full-size image, so the saved page matches the preview.")
    code(doc, """
static List<double> brightnessContrast(double brightness, double contrast) {
  final offset = 128 * (1 - contrast) + brightness * 255;
  return [
    contrast, 0, 0, 0, offset,
    0, contrast, 0, 0, offset,
    0, 0, contrast, 0, offset,
    0, 0, 0, 1, 0,
  ];
}
""")
    para(doc, "Grayscale is a saturation matrix with saturation 0. B & W is grayscale followed by strong contrast. Magic raises saturation and contrast slightly. Matrices are combined with matrix multiplication, so the filter is applied first and brightness and contrast after it.")
    heading(doc, "9.2 Background isolate for image work", 2)
    para(doc, "Decoding and changing a 2400-pixel photo takes long enough to freeze the screen. The image work in image_tools.dart therefore runs through compute(), which starts a separate Dart isolate. The interface keeps animating a progress indicator while the isolate works. The editor also makes a 1200-pixel working copy once, so previews are fast.")
    heading(doc, "9.3 Crop stored as fractions", 2)
    para(doc, "The crop rectangle is stored from 0 to 1 instead of in pixels. The same crop works on the small preview and the full-size image. When the page is rotated, the crop rectangle is rotated with it. For a clockwise turn, a point (x, y) moves to (1 - y, x):")
    code(doc, """
// clockwise
_crop = Rect.fromLTRB(1 - c.bottom, c.left, 1 - c.top, c.right);
// anticlockwise
_crop = Rect.fromLTRB(c.top, 1 - c.right, c.bottom, 1 - c.left);
""")
    heading(doc, "9.4 PDF creation", 2)
    para(doc, "PdfService adds one pw.Page per scanned page, using the page size and margin from Settings. Fit to image makes each PDF page the same shape as its photo. The file is written to the exports folder and can then be shared through share_plus.")
    heading(doc, "9.5 Saving data", 2)
    para(doc, "DocumentStore writes the whole list of documents to documents.json after every change, using jsonEncode on each object's toJson(). On start-up, main() waits for SettingsStore.load() and DocumentStore.load() before runApp, so the library is ready on the first frame.")

    heading(doc, "10. Input validation and screen states")
    table(doc, ["Input or situation", "What the app does"], [
        ("Empty document name", "Shows \"Please enter a name\" under the field; Save stays on the dialog"),
        ("Name shorter than 2 or longer than 40 characters", "Shows a length message; the field also has a 40-character counter"),
        ("Name with \\ / : * ? \" < > |", "Explains these symbols cannot be used, because the name becomes a file name"),
        ("Name already used", "Shows \"A document with this name already exists\" (not case-sensitive)"),
        ("Camera or gallery closed without a photo", "Nothing is added and no error is shown"),
        ("Camera or gallery cannot open", "Red message asks the user to allow access and try again"),
        ("Back with unsaved pages or edits", "Asks to discard; files of discarded pages are deleted"),
        ("Delete document, page or PDF", "Confirmation dialog (can be turned off in Settings)"),
        ("PDF for a document with no pages", "Explains a page must be added first"),
        ("No documents, no search results, no PDFs, no pages", "Each has its own empty state with an icon, a message and, where useful, a button"),
        ("Long work (import, save, PDF)", "Blocking progress dialog with a message"),
    ], [6.2, 10.0])

    heading(doc, "11. Testing")
    para(doc, "Automated unit tests (flutter test) check the logic that is easy to get wrong:")
    table(doc, ["Test", "Result"], [
        ("Original filter with no adjustment gives the identity matrix", "Pass"),
        ("Matrix multiply applies the second matrix first", "Pass"),
        ("Brightness adds the correct offset", "Pass"),
        ("The image package rotates clockwise for a positive angle", "Pass"),
        ("Name validation rejects empty and too long names", "Pass"),
        ("Name validation rejects file name symbols", "Pass"),
        ("Name validation accepts a normal name", "Pass"),
    ], [12.2, 4.0])
    para(doc, "Manual tests on the Pixel 7 emulator (Android):")
    table(doc, ["#", "Steps", "Expected result", "Result"], [
        (1, "Import three photos from the gallery", "Three numbered pages appear in New scan", "Pass"),
        (2, "Crop page 1 to the paper edges", "Desk is removed in the preview and the saved page", "Pass"),
        (3, "Rotate right, then left", "Page turns; crop stays on the same area", "Pass"),
        (4, "Choose B & W, raise contrast", "Preview updates while the slider moves", "Pass"),
        (5, "Save with an empty name", "Validation message, dialog stays open", "Pass"),
        (6, "Save as \"Lab Report 3\"", "Document opens with three pages", "Pass"),
        (7, "Reorder: drag page 3 to the top", "Order changes and is kept after restart", "Pass"),
        (8, "Create PDF", "File appears in PDF files with its size", "Pass"),
        (9, "Share PDF", "Android share sheet opens with the PDF", "Pass"),
        (10, "Search \"lab\", sort by name, switch to list", "Only matching documents, sorted, in a list", "Pass"),
        (11, "Close and reopen the app", "All documents, pages and settings remain", "Pass"),
        (12, "Switch to dark theme", "Every screen is readable in dark mode", "Pass"),
    ], [0.8, 5.6, 7.6, 2.0])

    heading(doc, "12. Work division")
    para(doc, "The project brief suggests splitting the work by camera and library, image processing, and PDF and files. All work is kept in one shared GitHub repository. Every member can explain and rewrite every screen, as required for the viva.")
    table(doc, ["Member", "Registration no.", "Main responsibility"],
          [(n, r, d) for n, r, d in MEMBERS], [3.4, 3.4, 9.4])

    heading(doc, "13. Limitations and future work")
    bullets(doc, [
        "Automatic page-edge detection and perspective correction (straightening a tilted page) would remove the manual crop step.",
        "On-device OCR with Google ML Kit could make the text searchable and copyable.",
        "Saving the PDF straight into the phone's Downloads folder; today it is saved in the app and shared from there.",
        "Optional cloud backup would need a backend, which is outside the scope of Option 1.",
    ])

    heading(doc, "14. Conclusion")
    para(doc, "Document Scanner meets the Option 1 requirement of a complete frontend. All 23 planned features are implemented, connected and working on an Android emulator. The project uses a clear layered structure, Flutter's built-in state management, background isolates for heavy image work, and non-destructive editing. It runs completely offline and gives a practical everyday tool for turning paper into shareable PDFs.")

    heading(doc, "Appendix A: How to run the project")
    bullets(doc, [
        "Open the folder D:\\document-scanner in Android Studio with the Flutter and Dart plugins.",
        "Start the Pixel_7 emulator from Device Manager, or connect an Android phone with USB debugging on.",
        "Run flutter pub get, then press Run (or type flutter run).",
        "To test without paper, drag photos of pages onto the emulator window and import them with Gallery.",
    ])

    heading(doc, "Appendix B: Project structure")
    code(doc, """
lib/
  main.dart                   app start, theme, first screen
  data/team.dart              group members and university
  models/
    scan_page.dart            one page and its edit settings
    scan_document.dart        a named list of pages
  services/
    document_store.dart       save, load, add, delete, reorder, validate
    image_tools.dart          rotate, crop, colour matrix in an isolate
    color_matrix.dart         filter, brightness and contrast maths
    pdf_service.dart          create, list and share PDFs
    settings_store.dart       user settings
    image_source_picker.dart  camera and gallery
  screens/
    splash, onboarding, main_shell, home, capture, edit_page,
    crop, document, page_viewer, exports, settings, about
  widgets/
    dialogs, empty_state, page_thumbnail, document_actions, page_import
test/widget_test.dart         unit tests
""")

    doc.core_properties.title = "Document Scanner - Project Report"
    doc.core_properties.author = "Areeb Tahir and Sohaib Dost"
    doc.save(OUT)
    print(OUT)


if __name__ == "__main__":
    build()
