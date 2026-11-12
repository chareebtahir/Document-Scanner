"""Generate phone-framed UI mock screenshots for the report and presentation."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "docs", "screenshots")
LOGO = os.path.join(ROOT, "assets", "images", "comsats-logo.png")
SAMPLES = os.path.join(ROOT, "docs", "sample_pages")
os.makedirs(OUT, exist_ok=True)

W, H = 1080, 2400
PURPLE = (74, 44, 127)
BLUE = (26, 93, 171)
NAVY = (23, 20, 58)
WHITE = (255, 255, 255)
INK = (30, 34, 43)
MUTED = (90, 96, 110)
MIST = (243, 244, 250)
CARD = (248, 249, 252)
GREEN = (46, 125, 50)
ERR = (180, 50, 50)


def font(size, bold=False):
    name = "arialbd.ttf" if bold else "arial.ttf"
    return ImageFont.truetype(os.path.join("C:/Windows/Fonts", name), size)


def rounded(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def status_bar(img, dark=False):
    d = ImageDraw.Draw(img)
    color = WHITE if dark else INK
    d.rectangle((0, 0, W, 80), fill=(0, 0, 0, 0) if dark else WHITE)
    d.text((48, 28), "12:44", font=font(28, True), fill=color)
    d.text((880, 28), "LTE  100%", font=font(24), fill=color)


def nav_bar(img, selected=0, dark=False):
    d = ImageDraw.Draw(img)
    bg = (32, 32, 38) if dark else WHITE
    d.rectangle((0, H - 180, W, H), fill=bg)
    d.line((0, H - 180, W, H - 180), fill=(220, 220, 225) if not dark else (60, 60, 70), width=2)
    labels = [("Documents", 0), ("PDF files", 1), ("Settings", 2)]
    xs = [180, 540, 900]
    for (label, idx), x in zip(labels, xs):
        color = BLUE if idx == selected else MUTED
        if dark and idx == selected:
            color = (140, 180, 255)
        d.ellipse((x - 18, H - 140, x + 18, H - 104), fill=color if idx == selected else (70, 70, 80) if dark else (210, 214, 220))
        d.text((x, H - 90), label, font=font(24), fill=color, anchor="mt")


def app_bar(d, title, dark=False, back=False, actions=None):
    bg = (32, 32, 38) if dark else WHITE
    d.rectangle((0, 80, W, 220), fill=bg)
    color = WHITE if dark else INK
    if back:
        d.polygon([(48, 150), (78, 130), (78, 170)], fill=color)
        d.text((110, 135), title, font=font(40, True), fill=color)
    else:
        try:
            logo = Image.open(LOGO).convert("RGBA").resize((64, 64))
            # paste later by caller if needed
        except Exception:
            pass
        d.text((48, 135), title, font=font(40, True), fill=color)
    if actions:
        x = W - 60
        for a in reversed(actions):
            d.text((x, 135), a, font=font(28), fill=color, anchor="rt")
            x -= 90


def empty_circle(d, icon_text, y=900):
    d.ellipse((W // 2 - 110, y, W // 2 + 110, y + 220), fill=(210, 225, 245))
    d.text((W // 2, y + 110), icon_text, font=font(64), fill=BLUE, anchor="mm")


def paste_logo(img, xy, size=64):
    logo = Image.open(LOGO).convert("RGBA").resize((size, size))
    img.paste(logo, xy, logo)


def paste_sample(img, page, box):
    path = os.path.join(SAMPLES, f"page_{page}.jpg")
    if not os.path.exists(path):
        return
    x0, y0, x1, y1 = box
    thumb = Image.open(path).convert("RGB")
    thumb = thumb.resize((x1 - x0, y1 - y0), Image.Resampling.LANCZOS)
    img.paste(thumb, (x0, y0))


def save(img, name):
    path = os.path.join(OUT, name)
    img.save(path, "PNG")
    print(path)


def splash():
    img = Image.new("RGB", (W, H), NAVY)
    d = ImageDraw.Draw(img)
    for i in range(H):
        t = i / H
        c = tuple(int(PURPLE[j] * (1 - t) + BLUE[j] * t) for j in range(3))
        d.line((0, i, W, i), fill=c)
    status_bar(img, dark=True)
    rounded(d, (W // 2 - 140, 720, W // 2 + 140, 1000), 48, WHITE)
    d.text((W // 2, 860), "📄", font=font(90), anchor="mm")
    d.text((W // 2, 1080), "Document Scanner", font=font(56, True), fill=WHITE, anchor="mt")
    d.text((W // 2, 1170), "Paper to PDF, on your phone", font=font(32), fill=(220, 230, 255), anchor="mt")
    paste_logo(img, (W // 2 - 64, 1900), 128)
    d.text((W // 2, 2060), "COMSATS University Islamabad", font=font(28, True), fill=WHITE, anchor="mt")
    save(img, "01_splash.png")


def onboarding():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    d.text((W - 80, 120), "Skip", font=font(30), fill=MUTED, anchor="rt")
    d.ellipse((W // 2 - 180, 520, W // 2 + 180, 880), fill=(220, 235, 250))
    d.text((W // 2, 700), "📷", font=font(100), anchor="mm")
    d.text((W // 2, 1000), "Capture any page", font=font(48, True), fill=INK, anchor="mt")
    d.text((W // 2, 1100), "Take a photo with the camera or",
           font=font(30), fill=MUTED, anchor="mt")
    d.text((W // 2, 1145), "import pictures from your gallery.",
           font=font(30), fill=MUTED, anchor="mt")
    for i, x in enumerate([480, 540, 600]):
        d.rounded_rectangle((x - (20 if i == 0 else 8), 1500, x + (20 if i == 0 else 8), 1516), 8, fill=BLUE if i == 0 else (200, 205, 215))
    rounded(d, (80, H - 220, W - 80, H - 100), 28, BLUE)
    d.text((W // 2, H - 160), "Next", font=font(34, True), fill=WHITE, anchor="mm")
    save(img, "02_onboarding.png")


def home_empty():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    paste_logo(img, (36, 120), 72)
    d.text((130, 140), "My Documents", font=font(40, True), fill=INK)
    d.text((W - 160, 145), "☰", font=font(36), fill=MUTED)
    empty_circle(d, "📁", 780)
    d.text((W // 2, 1100), "No documents yet", font=font(42, True), fill=INK, anchor="mt")
    d.text((W // 2, 1180), "Scan a page with the camera or import",
           font=font(28), fill=MUTED, anchor="mt")
    d.text((W // 2, 1220), "a photo to make your first document.",
           font=font(28), fill=MUTED, anchor="mt")
    rounded(d, (280, 1320, 800, 1420), 28, BLUE)
    d.text((540, 1370), "Start scanning", font=font(30, True), fill=WHITE, anchor="mm")
    rounded(d, (300, H - 340, 780, H - 230), 40, BLUE)
    d.text((540, H - 285), "＋  Scan", font=font(32, True), fill=WHITE, anchor="mm")
    nav_bar(img, 0)
    save(img, "03_home_empty.png")


def capture():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    app_bar(d, "New scan", back=True)
    rounded(d, (760, 120, 1020, 190), 24, BLUE)
    d.text((890, 155), "✓ Save", font=font(28, True), fill=WHITE, anchor="mm")
    d.text((48, 250), "3 pages", font=font(32, True), fill=INK)
    d.text((W - 48, 255), "Tap a page to edit it", font=font(24), fill=MUTED, anchor="rt")
    boxes = [(48, 320, 340, 720), (370, 320, 662, 720), (692, 320, 984, 720)]
    for i, box in enumerate(boxes, 1):
        rounded(d, box, 20, MIST)
        paste_sample(img, i, (box[0] + 8, box[1] + 8, box[2] - 8, box[3] - 50))
        d.ellipse((box[0] + 16, box[3] - 70, box[0] + 56, box[3] - 30), fill=(0, 0, 0, 160))
        # redraw number on dark chip
        d.rounded_rectangle((box[0] + 16, box[3] - 48, box[0] + 56, box[3] - 16), 10, fill=(0, 0, 0))
        d.text((box[0] + 36, box[3] - 32), str(i), font=font(22, True), fill=WHITE, anchor="mm")
        d.ellipse((box[2] - 56, box[1] + 12, box[2] - 16, box[1] + 52), fill=(230, 235, 245))
        d.text((box[2] - 36, box[1] + 32), "×", font=font(28), fill=INK, anchor="mm")
    rounded(d, (48, H - 280, 500, H - 160), 28, BLUE)
    d.text((274, H - 220), "📷 Camera", font=font(30, True), fill=WHITE, anchor="mm")
    rounded(d, (540, H - 280, 1032, H - 160), 28, WHITE)
    d.rounded_rectangle((540, H - 280, 1032, H - 160), 28, outline=BLUE, width=4)
    d.text((786, H - 220), "🖼 Gallery", font=font(30, True), fill=BLUE, anchor="mm")
    save(img, "04_capture.png")


def save_dialog():
    img = Image.new("RGB", (W, H), (40, 40, 45))
    d = ImageDraw.Draw(img)
    # dimmed background hint
    home = Image.open(os.path.join(OUT, "04_capture.png")).convert("RGB")
    home = home.point(lambda p: int(p * 0.35))
    img.paste(home)
    d = ImageDraw.Draw(img)
    rounded(d, (80, 700, 1000, 1400), 36, WHITE)
    d.text((120, 760), "Save document", font=font(40, True), fill=INK)
    rounded(d, (120, 860, 960, 1000), 20, MIST)
    d.text((150, 900), "Document name", font=font(22), fill=MUTED)
    d.text((150, 940), "Lab Report 3", font=font(32, True), fill=INK)
    d.text((900, 940), "12/40", font=font(22), fill=MUTED, anchor="rt")
    rounded(d, (520, 1220, 720, 1320), 20, MIST)
    d.text((620, 1270), "Cancel", font=font(28), fill=MUTED, anchor="mm")
    rounded(d, (760, 1220, 960, 1320), 20, BLUE)
    d.text((860, 1270), "Save", font=font(28, True), fill=WHITE, anchor="mm")
    save(img, "05_save_dialog.png")


def crop():
    img = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(img)
    status_bar(img, dark=True)
    d.text((80, 130), "← Crop", font=font(40, True), fill=WHITE)
    rounded(d, (620, 120, 820, 190), 20, (50, 50, 55))
    d.text((720, 155), "Full page", font=font(24), fill=WHITE, anchor="mm")
    rounded(d, (840, 120, 1020, 190), 20, BLUE)
    d.text((930, 155), "Apply", font=font(28, True), fill=WHITE, anchor="mm")
    # page in center
    paste_sample(img, 1, (120, 360, 960, 1700))
    # crop frame
    frame = (180, 420, 900, 1580)
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle((0, 280, W, 1900), fill=(0, 0, 0, 140))
    od.rectangle(frame, fill=(0, 0, 0, 0))
    # punch hole: redraw sample inside frame area by compositing differently
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    d = ImageDraw.Draw(img)
    paste_sample(img, 1, frame)
    d.rectangle(frame, outline=(140, 180, 255), width=4)
    for c in [(frame[0], frame[1]), (frame[2], frame[1]), (frame[0], frame[3]), (frame[2], frame[3])]:
        d.ellipse((c[0] - 16, c[1] - 16, c[0] + 16, c[1] + 16), fill=(140, 180, 255))
        d.ellipse((c[0] - 6, c[1] - 6, c[0] + 6, c[1] + 6), fill=WHITE)
    d.text((W // 2, H - 120), "Drag a corner to resize. Drag inside to move.",
           font=font(26), fill=(200, 200, 200), anchor="mt")
    save(img, "06_crop.png")


def edit_filters():
    img = Image.new("RGB", (W, H), (21, 22, 26))
    d = ImageDraw.Draw(img)
    status_bar(img, dark=True)
    d.text((80, 130), "← Edit page", font=font(40, True), fill=WHITE)
    d.text((720, 140), "Reset", font=font(28), fill=(180, 180, 190))
    rounded(d, (860, 120, 1020, 190), 20, BLUE)
    d.text((940, 155), "Done", font=font(28, True), fill=WHITE, anchor="mm")
    paste_sample(img, 1, (140, 280, 940, 1500))
    # filter panel
    d.rectangle((0, 1550, W, 1850), fill=(31, 32, 38))
    labels = ["Original", "Grayscale", "B & W", "Magic"]
    for i, lab in enumerate(labels):
        x = 60 + i * 250
        box = (x, 1580, x + 200, 1760)
        rounded(d, box, 16, (50, 52, 60))
        paste_sample(img, 1, (x + 10, 1590, x + 190, 1720))
        if i == 2:
            d.rectangle(box, outline=(140, 180, 255), width=5)
        d.text((x + 100, 1795), lab, font=font(22, True if i == 2 else False),
               fill=WHITE if i == 2 else (180, 180, 190), anchor="mt")
    tools = ["Crop", "Left", "Right", "Adjust", "Filters"]
    for i, t in enumerate(tools):
        x = 108 + i * 200
        color = (140, 180, 255) if t == "Filters" else WHITE
        d.text((x, 2100), "⬤", font=font(28), fill=color, anchor="mt")
        d.text((x, 2160), t, font=font(24), fill=color, anchor="mt")
    save(img, "07_edit_filters.png")


def edit_adjust():
    img = Image.new("RGB", (W, H), (21, 22, 26))
    d = ImageDraw.Draw(img)
    status_bar(img, dark=True)
    d.text((80, 130), "← Edit page", font=font(40, True), fill=WHITE)
    rounded(d, (860, 120, 1020, 190), 20, BLUE)
    d.text((940, 155), "Done", font=font(28, True), fill=WHITE, anchor="mm")
    paste_sample(img, 2, (140, 280, 940, 1450))
    d.rectangle((0, 1500, W, 1850), fill=(31, 32, 38))
    d.text((48, 1540), "☀ Brightness", font=font(28), fill=WHITE)
    d.line((280, 1560, 900, 1560), fill=(80, 80, 90), width=8)
    d.line((280, 1560, 620, 1560), fill=BLUE, width=8)
    d.ellipse((600, 1544, 640, 1576), fill=BLUE)
    d.text((980, 1540), "+20", font=font(26), fill=(180, 180, 190), anchor="rt")
    d.text((48, 1680), "◐ Contrast", font=font(28), fill=WHITE)
    d.line((280, 1700, 900, 1700), fill=(80, 80, 90), width=8)
    d.line((280, 1700, 700, 1700), fill=BLUE, width=8)
    d.ellipse((680, 1684, 720, 1716), fill=BLUE)
    d.text((980, 1680), "130%", font=font(26), fill=(180, 180, 190), anchor="rt")
    tools = ["Crop", "Left", "Right", "Adjust", "Filters"]
    for i, t in enumerate(tools):
        x = 108 + i * 200
        color = (140, 180, 255) if t == "Adjust" else WHITE
        d.text((x, 2100), "⬤", font=font(28), fill=color, anchor="mt")
        d.text((x, 2160), t, font=font(24), fill=color, anchor="mt")
    save(img, "08_edit_adjust.png")


def document():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    d.text((48, 130), "←", font=font(44), fill=INK)
    d.text((110, 120), "Lab Report 3", font=font(36, True), fill=INK)
    d.text((110, 170), "3 pages  ·  12 Nov 2026, 12:40 AM", font=font(22), fill=MUTED)
    d.text((W - 48, 140), "⋮", font=font(40), fill=MUTED, anchor="rt")
    boxes = [(48, 260, 500, 900), (540, 260, 992, 900), (48, 940, 500, 1580)]
    for i, box in enumerate(boxes, 1):
        rounded(d, box, 24, MIST)
        paste_sample(img, i, (box[0] + 12, box[1] + 12, box[2] - 12, box[3] - 12))
        d.rounded_rectangle((box[0] + 20, box[3] - 60, box[0] + 70, box[3] - 20), 12, fill=(0, 0, 0))
        d.text((box[0] + 45, box[3] - 40), str(i), font=font(24, True), fill=WHITE, anchor="mm")
    for i, (label, x0, x1, filled) in enumerate([
        ("＋ Add", 40, 340, False), ("PDF", 370, 670, False), ("Share", 700, 1040, True)
    ]):
        if filled:
            rounded(d, (x0, H - 220, x1, H - 110), 24, BLUE)
            d.text(((x0 + x1) // 2, H - 165), label, font=font(28, True), fill=WHITE, anchor="mm")
        else:
            d.rounded_rectangle((x0, H - 220, x1, H - 110), 24, outline=BLUE, width=3)
            d.text(((x0 + x1) // 2, H - 165), label, font=font(28, True), fill=BLUE, anchor="mm")
    save(img, "09_document.png")


def reorder():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    d.text((48, 130), "←", font=font(44), fill=INK)
    d.text((110, 125), "Lab Report 3", font=font(36, True), fill=INK)
    d.text((W - 80, 135), "✓", font=font(40, True), fill=BLUE, anchor="rt")
    rounded(d, (48, 240, 1032, 360), 20, (230, 235, 250))
    d.text((80, 280), "ℹ  Hold and drag the handle to change page order.", font=font(26), fill=INK)
    for i, title in enumerate(["Page 1", "Page 2", "Page 3"], 1):
        y = 400 + (i - 1) * 280
        rounded(d, (48, y, 1032, y + 240), 20, CARD)
        paste_sample(img, i, (70, y + 30, 220, y + 210))
        d.text((260, y + 70), title, font=font(34, True), fill=INK)
        d.text((260, y + 130), "Edited" if i == 1 else "Original", font=font(26), fill=MUTED)
        d.text((960, y + 100), "≡", font=font(48), fill=MUTED, anchor="mm")
    save(img, "10_reorder.png")


def viewer():
    img = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(img)
    status_bar(img, dark=True)
    d.text((48, 130), "← Page 1 of 3", font=font(36, True), fill=WHITE)
    d.text((W - 200, 130), "✎  ↗  🗑", font=font(28), fill=WHITE)
    paste_sample(img, 1, (80, 280, 1000, 2000))
    d.text((W // 2, H - 100), "Pinch to zoom  ·  Swipe for the next page",
           font=font(26), fill=(160, 160, 160), anchor="mt")
    save(img, "11_viewer.png")


def home():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    paste_logo(img, (36, 120), 72)
    d.text((130, 140), "My Documents", font=font(40, True), fill=INK)
    rounded(d, (48, 230, 1032, 340), 24, MIST)
    d.text((80, 265), "🔍  Search documents", font=font(28), fill=MUTED)
    d.text((48, 370), "2 documents  ·  5 pages", font=font(26), fill=MUTED)
    d.text((W - 48, 370), "Newest first", font=font(24), fill=MUTED, anchor="rt")
    # cards
    for i, (name, pages, box) in enumerate([
        ("Lab Report 3", "3 pages", (48, 430, 500, 1100)),
        ("Fee Challan", "1 page", (540, 430, 992, 1100)),
        ("Meeting Notes", "1 page", (48, 1140, 500, 1810)),
    ]):
        rounded(d, box, 24, CARD)
        paste_sample(img, min(i + 1, 3), (box[0] + 16, box[1] + 16, box[2] - 16, box[3] - 140))
        d.text((box[0] + 24, box[3] - 100), name, font=font(28, True), fill=INK)
        d.text((box[0] + 24, box[3] - 55), f"{pages}  ·  12 Nov 2026", font=font(22), fill=MUTED)
    rounded(d, (300, H - 340, 780, H - 230), 40, BLUE)
    d.text((540, H - 285), "＋  Scan", font=font(32, True), fill=WHITE, anchor="mm")
    nav_bar(img, 0)
    save(img, "12_home.png")


def pdf_files():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    d.text((48, 140), "PDF files", font=font(40, True), fill=INK)
    d.text((W - 60, 145), "↻", font=font(36), fill=MUTED, anchor="rt")
    for i, (name, size) in enumerate([
        ("Lab_Report_3.pdf", "1.8 MB"),
        ("Fee_Challan.pdf", "620 KB"),
    ]):
        y = 260 + i * 180
        rounded(d, (48, y, 1032, y + 150), 24, CARD)
        d.ellipse((80, y + 35, 180, y + 115), fill=(255, 220, 220))
        d.text((130, y + 75), "PDF", font=font(22, True), fill=ERR, anchor="mm")
        d.text((220, y + 45), name, font=font(30, True), fill=INK)
        d.text((220, y + 95), f"{size}  ·  12 Nov 2026, 12:42 AM", font=font(24), fill=MUTED)
        d.text((980, y + 75), "⋮", font=font(36), fill=MUTED, anchor="mm")
    nav_bar(img, 1)
    save(img, "13_pdf_files.png")


def settings():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    d.text((48, 140), "Settings", font=font(40, True), fill=INK)
    d.text((48, 250), "APPEARANCE", font=font(22, True), fill=BLUE)
    rounded(d, (48, 300, 1032, 420), 24, MIST)
    for i, lab in enumerate(["System", "Light", "Dark"]):
        x0 = 70 + i * 320
        if lab == "System":
            rounded(d, (x0, 320, x0 + 280, 400), 18, BLUE)
            d.text((x0 + 140, 360), lab, font=font(26, True), fill=WHITE, anchor="mm")
        else:
            d.text((x0 + 140, 360), lab, font=font(26), fill=MUTED, anchor="mm")
    sections = [
        ("SCANNING", [("Default filter for new pages", "Original"), ("Image quality", "High")]),
        ("PDF", [("Page size", "A4"), ("Page margin", "Small")]),
        ("GENERAL", [("Ask before deleting", "On"), ("Show introduction again", ""), ("Delete all data", "")]),
        ("ABOUT", [("About this app", "Version, team and university")]),
    ]
    y = 470
    for head, items in sections:
        d.text((48, y), head, font=font(22, True), fill=BLUE)
        y += 50
        for title, sub in items:
            d.text((48, y), title, font=font(30), fill=ERR if "Delete" in title else INK)
            if sub:
                d.text((W - 48, y + 5), sub, font=font(26), fill=MUTED, anchor="rt")
            y += 90
    nav_bar(img, 2)
    save(img, "14_settings.png")


def share():
    img = Image.new("RGB", (W, H), (30, 30, 35))
    bg = Image.open(os.path.join(OUT, "09_document.png")).convert("RGB").point(lambda p: int(p * 0.3))
    img.paste(bg)
    d = ImageDraw.Draw(img)
    rounded(d, (0, 1100, W, H), 40, WHITE)
    d.rounded_rectangle((480, 1130, 600, 1148), 8, fill=(200, 200, 205))
    d.text((48, 1200), "Share Lab_Report_3.pdf", font=font(34, True), fill=INK)
    apps = [("Drive", "☁"), ("Gmail", "✉"), ("WhatsApp", "💬"), ("Files", "📁"), ("Bluetooth", "📶"), ("Nearby", "📡")]
    for i, (name, icon) in enumerate(apps):
        x = 90 + (i % 3) * 330
        y = 1320 + (i // 3) * 280
        d.ellipse((x, y, x + 120, y + 120), fill=MIST)
        d.text((x + 60, y + 60), icon, font=font(40), anchor="mm")
        d.text((x + 60, y + 150), name, font=font(24), fill=INK, anchor="mt")
    save(img, "15_share.png")


def about():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    status_bar(img)
    d.text((48, 130), "← About", font=font(40, True), fill=INK)
    for i in range(280, 780):
        t = (i - 280) / 500
        c = tuple(int(PURPLE[j] * (1 - t) + BLUE[j] * t) for j in range(3))
        d.line((48, i, 1032, i), fill=c)
    paste_logo(img, (W // 2 - 64, 320), 128)
    d.text((W // 2, 480), "Document Scanner", font=font(40, True), fill=WHITE, anchor="mt")
    d.text((W // 2, 550), "Version 1.0.0", font=font(26), fill=(220, 230, 255), anchor="mt")
    d.text((W // 2, 620), "COMSATS University Islamabad", font=font(28, True), fill=WHITE, anchor="mt")
    d.text((W // 2, 680), "Mobile Application Development", font=font(24), fill=(220, 230, 255), anchor="mt")
    d.text((48, 840), "Group members", font=font(32, True), fill=INK)
    for i, (name, roll, role) in enumerate([
        ("Areeb Tahir", "FA23-BCS-468", "Camera, import and document library"),
        ("Sohaib Dost", "SP24-BCS-030", "Crop, image processing, PDF and sharing"),
    ]):
        y = 920 + i * 200
        rounded(d, (48, y, 1032, y + 170), 24, CARD)
        d.ellipse((80, y + 40, 180, y + 140), fill=(220, 235, 250))
        d.text((130, y + 90), name[0], font=font(40, True), fill=BLUE, anchor="mm")
        d.text((220, y + 45), name, font=font(32, True), fill=INK)
        d.text((220, y + 95), roll, font=font(24), fill=MUTED)
        d.text((220, y + 130), role, font=font(22), fill=MUTED)
    save(img, "16_about.png")


def dark():
    img = Image.new("RGB", (W, H), (18, 18, 22))
    d = ImageDraw.Draw(img)
    status_bar(img, dark=True)
    paste_logo(img, (36, 120), 72)
    d.text((130, 140), "My Documents", font=font(40, True), fill=WHITE)
    rounded(d, (48, 230, 1032, 340), 24, (40, 42, 50))
    d.text((80, 265), "🔍  Search documents", font=font(28), fill=(150, 150, 160))
    d.text((48, 370), "2 documents  ·  5 pages", font=font(26), fill=(150, 150, 160))
    for i, (name, box) in enumerate([
        ("Lab Report 3", (48, 430, 500, 1100)),
        ("Fee Challan", (540, 430, 992, 1100)),
    ]):
        rounded(d, box, 24, (32, 34, 42))
        paste_sample(img, i + 1, (box[0] + 16, box[1] + 16, box[2] - 16, box[3] - 140))
        d.text((box[0] + 24, box[3] - 100), name, font=font(28, True), fill=WHITE)
        d.text((box[0] + 24, box[3] - 55), "Updated today", font=font(22), fill=(150, 150, 160))
    rounded(d, (300, H - 340, 780, H - 230), 40, BLUE)
    d.text((540, H - 285), "＋  Scan", font=font(32, True), fill=WHITE, anchor="mm")
    nav_bar(img, 0, dark=True)
    save(img, "17_dark.png")


def main():
    splash()
    onboarding()
    home_empty()
    capture()
    save_dialog()
    crop()
    edit_filters()
    edit_adjust()
    document()
    reorder()
    viewer()
    home()
    pdf_files()
    settings()
    share()
    about()
    dark()
    print("DONE", len(os.listdir(OUT)), "files")


if __name__ == "__main__":
    main()
