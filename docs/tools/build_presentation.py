"""Builds the class presentation for the Document Scanner app.

Same layout system as the Explore Pakistan deck: Cambria titles, Calibri body,
widescreen 13.333 x 7.5 in. Colours come from the COMSATS logo.
"""
import os

from lxml import etree
from PIL import Image, ImageChops, ImageDraw
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.oxml.ns import qn
from pptx.util import Emu, Inches, Pt

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DOCS = os.path.join(ROOT, "docs")
SHOTS = os.path.join(DOCS, "screenshots")
BUILD = os.path.join(DOCS, "tools", "build")
LOGO = os.path.join(ROOT, "assets", "images", "comsats-logo.png")
OUT = os.path.join(DOCS, "Document-Scanner-Presentation.pptx")

NAVY = "17143A"
PURPLE = "4A2C7F"
BLUE = "1A5DAB"
SKY = "8FB8EA"
MIST = "F3F4FA"
WHITE = "FFFFFF"
INK = "17143A"
MUTED = "565A6E"
SOFT = "CFD3EA"

os.makedirs(BUILD, exist_ok=True)


def rgb(value):
    return RGBColor.from_string(value)


def make_circle_logo(src, name):
    image = Image.open(src).convert("RGBA")
    bbox = image.getbbox()
    image = image.crop(bbox)
    side = max(image.width, image.height)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(image, ((side - image.width) // 2, (side - image.height) // 2), image)
    mask = Image.new("L", (side, side), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, side - 1, side - 1), fill=255)
    canvas.putalpha(ImageChops.multiply(canvas.getchannel("A"), mask))
    path = os.path.join(BUILD, name)
    canvas.save(path)
    return path


def phone(src, name, radius=46):
    """Screenshot with rounded corners and a dark phone frame."""
    shot = Image.open(src).convert("RGBA")
    w, h = shot.size
    pad = 26
    frame = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle((0, 0, frame.width - 1, frame.height - 1), radius=radius + pad, fill=(22, 22, 28, 255))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
    shot.putalpha(mask)
    frame.paste(shot, (pad, pad), shot)
    path = os.path.join(BUILD, name)
    frame.save(path)
    return path


def set_run(run, font, size, color, bold=False, italic=False):
    run.font.name = font
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = rgb(color)
    rpr = run._r.get_or_add_rPr()
    for tag in ("latin", "ea", "cs"):
        node = rpr.find(qn(f"a:{tag}"))
        if node is None:
            node = etree.SubElement(rpr, qn(f"a:{tag}"))
        node.set("typeface", font)


def add_text(slide, text, x, y, w, h, font="Calibri", size=16, color=INK, bold=False, italic=False, align="left", anchor="top"):
    shape = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    frame = shape.text_frame
    frame.word_wrap = True
    frame.auto_size = None
    frame.margin_left = frame.margin_right = frame.margin_top = frame.margin_bottom = 0
    frame.vertical_anchor = {"top": MSO_ANCHOR.TOP, "middle": MSO_ANCHOR.MIDDLE, "bottom": MSO_ANCHOR.BOTTOM}[anchor]
    paragraph = frame.paragraphs[0]
    paragraph.alignment = {"left": PP_ALIGN.LEFT, "center": PP_ALIGN.CENTER, "right": PP_ALIGN.RIGHT}[align]
    run = paragraph.add_run()
    run.text = text
    set_run(run, font, size, color, bold, italic)
    return shape


def add_lines(slide, lines, x, y, w, h):
    shape = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    frame = shape.text_frame
    frame.word_wrap = True
    frame.auto_size = None
    frame.margin_left = frame.margin_right = frame.margin_top = frame.margin_bottom = 0
    for index, line in enumerate(lines):
        paragraph = frame.paragraphs[0] if index == 0 else frame.add_paragraph()
        paragraph.space_before = Pt(line.get("before", 0))
        run = paragraph.add_run()
        run.text = line["text"]
        set_run(run, line.get("font", "Calibri"), line.get("size", 16), line.get("color", INK), line.get("bold", False))
    return shape


def rect(slide, x, y, w, h, fill, rounded=False, curve=0.12):
    kind = MSO_SHAPE.ROUNDED_RECTANGLE if rounded else MSO_SHAPE.RECTANGLE
    shape = slide.shapes.add_shape(kind, Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = rgb(fill)
    shape.line.fill.background()
    shape.shadow.inherit = False
    if rounded:
        shape.adjustments[0] = curve
    return shape


def oval(slide, x, y, w, h, fill):
    shape = slide.shapes.add_shape(MSO_SHAPE.OVAL, Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = rgb(fill)
    shape.line.fill.background()
    shape.shadow.inherit = False
    return shape


def picture_h(slide, path, x, y, h):
    """Adds a picture by height and returns its width in inches."""
    with Image.open(path) as im:
        w = h * im.width / im.height
    slide.shapes.add_picture(path, Inches(x), Inches(y), Inches(w), Inches(h))
    return w


def footer(slide, number, dark=False):
    color = SOFT if dark else MUTED
    add_text(slide, "Document Scanner   ·   COMSATS University Islamabad", 0.55, 7.05, 9.2, 0.28, size=12, color=color)
    add_text(slide, f"{number:02d}", 11.9, 7.05, 0.85, 0.28, size=12, color=color, align="right")


def notes(slide, text):
    slide.notes_slide.notes_text_frame.text = text


def new_slide(prs, dark=False):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    slide.background.fill.solid()
    slide.background.fill.fore_color.rgb = rgb(NAVY if dark else WHITE)
    return slide


def title(slide, text, sub=None):
    add_text(slide, text, 0.55, 0.4, 11.5, 0.7, font="Cambria", size=36, color=INK, bold=True)
    if sub:
        add_text(slide, sub, 0.55, 1.12, 11.5, 0.45, size=17, color=MUTED)


def shot(name):
    return os.path.join(SHOTS, name)


def build():
    logo = make_circle_logo(LOGO, "comsats-circle.png")
    p = {}
    for key in ["01_splash", "03_home_empty", "04_capture", "05_save_dialog", "06_crop", "07_edit_filters", "08_edit_adjust",
                "09_document", "10_reorder", "11_viewer", "12_home", "13_pdf_files", "14_settings", "15_share", "16_about", "17_dark"]:
        if os.path.exists(shot(key + ".png")):
            p[key] = phone(shot(key + ".png"), key + "-phone.png")

    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    prs.core_properties.title = "Document Scanner"
    prs.core_properties.author = "Areeb Tahir and Sohaib Dost"

    # 1 Title
    s = new_slide(prs, dark=True)
    s.shapes.add_picture(logo, Inches(0.55), Inches(0.48), Inches(0.72), Inches(0.72))
    add_text(s, "COMSATS UNIVERSITY ISLAMABAD", 1.45, 0.62, 6, 0.4, size=14, color=SKY, bold=True, anchor="middle")
    add_text(s, "Document Scanner", 0.55, 1.75, 7.4, 1.05, font="Cambria", size=50, color=WHITE, bold=True)
    add_text(s, "Paper to PDF, on your phone", 0.55, 2.85, 7, 0.55, font="Cambria", size=26, color=SKY)
    add_text(s, "A Flutter app for Android that captures paper pages, cleans them up, and saves them as one multi-page PDF. Fully offline.", 0.55, 3.65, 6.8, 1.2, size=18, color=SOFT)
    add_lines(s, [
        {"text": "Areeb Tahir", "size": 18, "color": WHITE, "bold": True},
        {"text": "FA23-BCS-468", "size": 15, "color": SKY, "before": 2},
        {"text": "Sohaib Dost", "size": 18, "color": WHITE, "bold": True, "before": 12},
        {"text": "SP24-BCS-030", "size": 15, "color": SKY, "before": 2},
    ], 0.55, 5.1, 4.2, 1.7)
    if "01_splash" in p:
        picture_h(s, p["01_splash"], 9.15, 0.45, 6.45)
    footer(s, 1, dark=True)
    notes(s, "Name the university, then both members with roll numbers. Say this is Mobile Application Development, Mid Lab, Option 1: a 100 percent frontend app that runs on Android.")

    # 2 Problem
    s = new_slide(prs)
    title(s, "Why a phone photo is not a scan", "Four problems the app fixes, each with its own tool.")
    problems = [
        ("Background", "The desk shows around the page.", "Crop"),
        ("Sideways", "The page is turned or upside down.", "Rotate"),
        ("Bad light", "Too dark, too bright, or flat.", "Brightness, contrast, filters"),
        ("Many files", "Pages are separate and out of order.", "Multi-page PDF, reorder"),
    ]
    for i, (head, body, fix) in enumerate(problems):
        x = 0.55 + i * 3.1
        rect(s, x, 1.9, 2.9, 3.0, MIST, rounded=True, curve=0.1)
        add_text(s, head, x + 0.25, 2.1, 2.5, 0.5, font="Cambria", size=22, color=PURPLE, bold=True)
        add_text(s, body, x + 0.25, 2.75, 2.45, 1.0, size=16, color=INK)
        rect(s, x + 0.25, 3.95, 2.4, 0.62, BLUE, rounded=True, curve=0.3)
        add_text(s, fix, x + 0.35, 3.95, 2.2, 0.62, size=13.5, color=WHITE, bold=True, align="center", anchor="middle")
    rect(s, 0.55, 5.25, 12.2, 1.4, NAVY, rounded=True, curve=0.1)
    add_text(s, "Option 1: 100% frontend", 0.85, 5.42, 6, 0.45, font="Cambria", size=22, color=WHITE, bold=True)
    add_text(s, "Every screen and flow is built and connected. No server, no account, no internet: photos, edits and PDFs stay on the phone.", 0.85, 5.92, 11.5, 0.6, size=16, color=SOFT)
    footer(s, 2)
    notes(s, "Each problem maps to one tool. Say clearly that the group chose Option 1, and that there is no backend.")

    # 3 Features
    s = new_slide(prs)
    title(s, "What the app does")
    feats = [
        ("01", "Capture", "Camera, or several photos from the gallery at once."),
        ("02", "Edit", "Crop, rotate, brightness, contrast, and four filters."),
        ("03", "Organise", "Multi-page documents, drag to reorder, rename."),
        ("04", "Find", "Search, four sort orders, grid or list view."),
        ("05", "Export", "PDF in A4, Letter, or fit to image, with margins."),
        ("06", "Share", "PDF or page images through any installed app."),
    ]
    for i, (num, head, body) in enumerate(feats):
        x = 0.55 + (i % 3) * 4.15
        y = 1.35 + (i // 3) * 2.7
        rect(s, x, y, 3.95, 2.5, MIST, rounded=True, curve=0.1)
        oval(s, x + 0.22, y + 0.28, 0.52, 0.52, PURPLE)
        add_text(s, num, x + 0.22, y + 0.28, 0.52, 0.52, size=12, color=WHITE, bold=True, align="center", anchor="middle")
        add_text(s, head, x + 0.88, y + 0.32, 2.85, 0.45, font="Cambria", size=20, color=INK, bold=True)
        add_text(s, body, x + 0.22, y + 1.05, 3.5, 1.2, size=16, color=INK)
    footer(s, 3)
    notes(s, "Read the six headings, not every line. These are the six groups of the 23-feature checklist in the report.")

    # 4 Capture flow
    s = new_slide(prs)
    title(s, "Capture: camera or gallery", "New scan collects pages first. Save asks for a name and checks it.")
    x = 0.7
    for key in ["03_home_empty", "04_capture", "05_save_dialog"]:
        if key in p:
            x += picture_h(s, p[key], x, 1.75, 5.05) + 0.45
    add_lines(s, [
        {"text": "image_picker", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE},
        {"text": "pickImage(camera) for one photo, pickMultiImage() for many. Both resize to 2400 px.", "size": 15, "before": 4},
        {"text": "Name validation", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE, "before": 16},
        {"text": "Required, 2 to 40 characters, no \\ / : * ? \" < > |, and not already used.", "size": 15, "before": 4},
        {"text": "Back without saving", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE, "before": 16},
        {"text": "PopScope asks first, then deletes the unsaved photos.", "size": 15, "before": 4},
    ], x + 0.1, 1.9, 12.75 - x - 0.1, 4.8)
    footer(s, 4)
    notes(s, "Show the empty library, the New scan screen with three pages, then the name dialog. Mention the validation rules from document_store.dart.")

    # 5 Editing
    s = new_slide(prs)
    title(s, "Edit: crop, rotate, adjust, filter", "The original photo is never changed. Edits are settings, so Reset always works.")
    x = 0.7
    for key in ["06_crop", "07_edit_filters", "08_edit_adjust"]:
        if key in p:
            x += picture_h(s, p[key], x, 1.75, 5.05) + 0.45
    add_lines(s, [
        {"text": "Crop", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE},
        {"text": "Four corner handles. Saved as fractions 0 to 1, so it fits any image size.", "size": 15, "before": 4},
        {"text": "Colour matrix", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE, "before": 16},
        {"text": "Filter, brightness and contrast become one 4 x 5 matrix. ColorFilter shows it live; the saved file uses the same numbers.", "size": 15, "before": 4},
        {"text": "Isolate", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE, "before": 16},
        {"text": "compute() runs the pixel work off the UI thread.", "size": 15, "before": 4},
    ], x + 0.1, 1.9, 12.75 - x - 0.1, 4.8)
    footer(s, 5)
    notes(s, "This is the slide examiners ask about. Explain non-destructive editing, then why the preview matches the saved image: same matrix. If asked what compute does, it runs a function in another isolate.")

    # 6 Documents
    s = new_slide(prs)
    title(s, "Organise: pages, order and viewer")
    x = 0.7
    for key in ["09_document", "10_reorder", "11_viewer"]:
        if key in p:
            x += picture_h(s, p[key], x, 1.35, 5.45) + 0.45
    add_lines(s, [
        {"text": "Document", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE},
        {"text": "Numbered page grid. Add, PDF and Share at the bottom.", "size": 15, "before": 4},
        {"text": "Reorder", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE, "before": 16},
        {"text": "ReorderableListView with drag handles. The new order is saved at once.", "size": 15, "before": 4},
        {"text": "Viewer", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE, "before": 16},
        {"text": "PageView to swipe, InteractiveViewer to pinch zoom.", "size": 15, "before": 4},
    ], x + 0.1, 1.5, 12.75 - x - 0.1, 5.0)
    footer(s, 6)
    notes(s, "Show the grid, switch to reorder, drag one page. Then open the viewer and zoom. Every change goes through DocumentStore, which saves documents.json and notifies the screens.")

    # 7 Library, PDF, settings
    s = new_slide(prs)
    title(s, "Find, export and set up")
    x = 0.7
    for key in ["12_home", "13_pdf_files", "14_settings"]:
        if key in p:
            x += picture_h(s, p[key], x, 1.35, 5.45) + 0.45
    add_lines(s, [
        {"text": "My Documents", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE},
        {"text": "Search, sort, grid or list. Menu: rename, PDF, share, delete.", "size": 15, "before": 4},
        {"text": "PDF files", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE, "before": 16},
        {"text": "Every exported PDF with size and date. Share or delete.", "size": 15, "before": 4},
        {"text": "Settings", "font": "Cambria", "size": 20, "bold": True, "color": PURPLE, "before": 16},
        {"text": "Theme, default filter, quality, PDF size and margin. Saved with shared_preferences.", "size": 15, "before": 4},
    ], x + 0.1, 1.5, 12.75 - x - 0.1, 5.0)
    footer(s, 7)
    notes(s, "Three tabs in the NavigationBar. Mention the pdf package makes one PDF page per scanned page, using the size from Settings.")

    # 8 Architecture
    s = new_slide(prs)
    title(s, "How the code is organised")
    cols = [
        ("Models", "ScanPage keeps the original photo and its edit settings. ScanDocument is a named list of pages. Both have toJson and fromJson."),
        ("Services", "DocumentStore saves and loads everything. ImageTools and ColorMatrix process images. PdfService makes and shares PDFs."),
        ("Screens", "Twelve screens, one file each. They read from the stores through ListenableBuilder and redraw on notifyListeners()."),
    ]
    for i, (head, body) in enumerate(cols):
        x = 0.55 + i * 4.15
        rect(s, x, 1.4, 3.95, 3.45, MIST, rounded=True, curve=0.1)
        add_text(s, head, x + 0.25, 1.6, 3.4, 0.55, font="Cambria", size=26, color=PURPLE, bold=True)
        add_text(s, body, x + 0.25, 2.35, 3.45, 2.3, size=16, color=INK)
    rect(s, 0.55, 5.15, 12.2, 1.5, NAVY, rounded=True, curve=0.1)
    add_text(s, "State: ChangeNotifier + ListenableBuilder", 0.85, 5.32, 11, 0.45, font="Cambria", size=22, color=WHITE, bold=True)
    add_text(s, "No extra state library. Shared data lives in two stores; short-lived values like a slider use setState. Data is saved to documents.json in the app folder.", 0.85, 5.82, 11.5, 0.7, size=16, color=SOFT)
    footer(s, 8)
    notes(s, "If asked where data is saved: getApplicationDocumentsDirectory from path_provider, then pages, exports, and documents.json. If asked why no Provider or Bloc: the built-in ChangeNotifier is enough for two stores.")

    # 9 Checklist
    s = new_slide(prs)
    title(s, "Feature checklist: 23 of 23", "Completion = accepted features / approved features x 100 = 100%")
    checklist = [
        "Splash with logo", "Introduction", "Camera scan", "Gallery import (multi)", "Crop", "Rotate",
        "Brightness and contrast", "Four filters", "Reset edits", "Multi-page documents", "Reorder pages",
        "Page viewer and zoom", "Delete with confirmation", "Rename with validation", "Search", "Sort, grid or list",
        "Create PDF", "Share PDF or images", "PDF files screen", "Settings", "Saved after restart",
        "Empty, loading, error states", "Light and dark theme",
    ]
    for i, item in enumerate(checklist):
        col, row = i % 3, i // 3
        x = 0.55 + col * 4.15
        y = 1.8 + row * 0.62
        oval(s, x, y + 0.06, 0.34, 0.34, BLUE)
        add_text(s, "✓", x, y + 0.06, 0.34, 0.34, size=12, color=WHITE, bold=True, align="center", anchor="middle")
        add_text(s, item, x + 0.5, y + 0.05, 3.5, 0.4, size=16, color=INK)
    footer(s, 9)
    notes(s, "This is the checklist the instructions ask groups to present. Each item is demonstrated in the next slide's demo path. OCR was optional and is listed as future work.")

    # 10 Demo
    s = new_slide(prs)
    title(s, "A five-minute demonstration", "Run on the Pixel 7 emulator. Not a browser.")
    steps = [
        ("01", "Import", "Scan, then Gallery: pick the three sample pages."),
        ("02", "Edit", "Crop page 1 to the paper, choose B & W, raise contrast."),
        ("03", "Save", "Try an empty name to show validation, then save."),
        ("04", "Reorder", "Drag page 3 to the top. Open the viewer and zoom."),
        ("05", "Export", "Create the PDF, open PDF files, then Share."),
    ]
    for i, (num, head, body) in enumerate(steps):
        x = 0.55 + i * 2.52
        rect(s, x, 1.85, 2.38, 4.55, MIST, rounded=True, curve=0.1)
        add_text(s, num, x + 0.18, 2.05, 2.05, 0.7, font="Cambria", size=28, color=BLUE, bold=True)
        add_text(s, head, x + 0.18, 2.85, 2.05, 0.6, font="Cambria", size=22, color=INK, bold=True)
        add_text(s, body, x + 0.18, 3.6, 2.05, 2.4, size=15.5, color=INK)
    footer(s, 10)
    notes(s, "Do the demo in this order and stop. The emulator must already be running before the exam starts. The sample pages are in docs/sample_pages; drag them onto the emulator if the gallery is empty.")

    # 11 Team
    s = new_slide(prs)
    title(s, "The group")
    s.shapes.add_picture(logo, Inches(0.55), Inches(1.25), Inches(1.15), Inches(1.15))
    add_lines(s, [
        {"text": "COMSATS University Islamabad", "font": "Cambria", "size": 22, "bold": True},
        {"text": "Mobile Application Development  ·  Mid Lab Assessment", "size": 16, "color": MUTED, "before": 4},
    ], 1.9, 1.4, 9, 0.9)
    members = [
        ("Areeb Tahir", "FA23-BCS-468", "Camera and gallery import, New scan, document library, splash and introduction."),
        ("Sohaib Dost", "SP24-BCS-030", "Crop, rotate, colour matrix filters, PDF export, PDF files, sharing and settings."),
    ]
    for i, (name, roll, part) in enumerate(members):
        x = 0.55 + i * 6.35
        rect(s, x, 2.8, 6.05, 3.6, MIST, rounded=True, curve=0.1)
        add_text(s, "GROUP MEMBER", x + 0.35, 3.05, 5, 0.3, size=13, color=BLUE, bold=True)
        add_text(s, name, x + 0.35, 3.45, 5.3, 0.7, font="Cambria", size=32, color=INK, bold=True)
        add_text(s, roll, x + 0.35, 4.25, 5, 0.4, size=18, color=PURPLE, bold=True)
        add_text(s, part, x + 0.35, 4.9, 5.3, 1.2, size=16, color=INK)
    footer(s, 11)
    notes(s, "Each member can explain every screen, not only their own part. That is a rule of the viva.")

    # 12 Future
    s = new_slide(prs)
    title(s, "What comes next")
    future = [
        ("Edge detection", "Find the page corners and straighten a tilted page automatically."),
        ("OCR", "On-device text recognition with ML Kit, to search and copy text."),
        ("Downloads", "Save PDFs straight into the phone's Downloads folder."),
    ]
    for i, (head, body) in enumerate(future):
        y = 1.45 + i * 1.6
        oval(s, 0.55, y, 0.7, 0.7, PURPLE)
        add_text(s, str(i + 1), 0.55, y, 0.7, 0.7, size=20, color=WHITE, bold=True, align="center", anchor="middle")
        add_text(s, head, 1.5, y - 0.02, 5.5, 0.45, font="Cambria", size=22, color=INK, bold=True)
        add_text(s, body, 1.5, y + 0.5, 5.6, 0.8, size=16, color=MUTED)
    if "17_dark" in p:
        picture_h(s, p["17_dark"], 8.6, 0.6, 6.1)
    footer(s, 12)
    notes(s, "Keep this short. OCR was optional in the brief. The screenshot shows the dark theme.")

    # 13 Close
    s = new_slide(prs, dark=True)
    s.shapes.add_picture(logo, Inches(0.55), Inches(0.5), Inches(0.78), Inches(0.78))
    add_text(s, "COMSATS UNIVERSITY ISLAMABAD", 1.5, 0.68, 6, 0.4, size=14, color=SKY, bold=True, anchor="middle")
    add_text(s, "Thank you", 0.55, 1.9, 7, 0.9, font="Cambria", size=54, color=WHITE, bold=True)
    add_text(s, "Questions", 0.55, 2.9, 6, 0.6, font="Cambria", size=28, color=SKY)
    add_text(s, "Document Scanner  ·  Flutter  ·  Android", 0.55, 4.0, 7, 0.4, size=18, color=SOFT)
    add_lines(s, [
        {"text": "Areeb Tahir   ·   FA23-BCS-468", "size": 16, "color": WHITE},
        {"text": "Sohaib Dost   ·   SP24-BCS-030", "size": 16, "color": WHITE, "before": 6},
    ], 0.55, 4.6, 6.5, 1.0)
    if "12_home" in p:
        picture_h(s, p["12_home"], 9.15, 0.45, 6.45)
    footer(s, 13, dark=True)
    notes(s, "Stop after the names and leave this slide up for questions.")

    prs.save(OUT)
    check(prs)
    print(OUT)


def check(prs):
    problems = []
    for index, slide in enumerate(prs.slides, 1):
        for shape in slide.shapes:
            if shape.left < 0 or shape.top < 0 or shape.left + shape.width > prs.slide_width + Emu(2000) or shape.top + shape.height > prs.slide_height + Emu(2000):
                problems.append(f"slide {index}: shape outside the slide")
    print("SLIDES", len(prs.slides), "BOUNDS", "ok" if not problems else problems)


if __name__ == "__main__":
    build()
