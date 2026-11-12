"""Makes three photos of paper pages on a desk, used to demo the scanner."""
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "sample_pages")
os.makedirs(OUT, exist_ok=True)


def font(size, bold=False):
    name = "arialbd.ttf" if bold else "arial.ttf"
    return ImageFont.truetype(os.path.join("C:/Windows/Fonts", name), size)


PAGES = [
    ("Lab Report 3", "Mobile Application Development", [
        "Objective",
        "To build a Flutter screen that lists items and opens a detail view.",
        "Apparatus",
        "Android Studio, Flutter SDK, Pixel 7 emulator.",
        "Procedure",
        "1. Create a new Flutter project.",
        "2. Add a ListView.builder with sample data.",
        "3. Use Navigator.push to open the detail screen.",
        "4. Pass the selected item as a constructor argument.",
        "Result",
        "The list scrolls smoothly and each item opens its own page.",
    ]),
    ("Fee Challan", "COMSATS University Islamabad", [
        "Student: Areeb Tahir",
        "Registration: FA23-BCS-468",
        "Semester: Fall 2026",
        "Tuition fee                     PKR 98,000",
        "Library fee                       PKR 2,500",
        "Sports fund                       PKR 1,500",
        "Total                          PKR 102,000",
        "Due date: 30 November 2026",
        "Bank copy",
    ]),
    ("Meeting Notes", "Group project, week 9", [
        "Attendees: Areeb, Sohaib",
        "Done: camera import, crop, filters",
        "Next: page reorder, PDF export",
        "Check every screen on the emulator",
        "Commit to the shared GitHub repository",
        "Practise the viva questions together",
        "Next meeting: Thursday, CLAB 10",
    ]),
]


def make_page(title, subtitle, lines, seed):
    random.seed(seed)
    paper = Image.new("RGB", (1240, 1754), (250, 248, 242))
    d = ImageDraw.Draw(paper)
    d.text((110, 120), title, font=font(72, True), fill=(25, 25, 30))
    d.text((110, 215), subtitle, font=font(38), fill=(70, 70, 80))
    d.line((110, 285, 1130, 285), fill=(40, 60, 120), width=4)
    y = 340
    for line in lines:
        bold = len(line.split()) <= 2 and not line[0].isdigit()
        d.text((110, y), line, font=font(40, bold), fill=(30, 30, 35))
        y += 92 if bold else 78
    for i in range(6):
        d.line((110, 1500 + i * 0, 1130, 1500), fill=(200, 200, 205), width=2)
    d.text((110, 1560), "Page signed: ____________________", font=font(34), fill=(60, 60, 70))

    desk = Image.new("RGB", (1800, 2400), (96, 70, 48))
    dd = ImageDraw.Draw(desk)
    for _ in range(140):
        x = random.randint(0, 1800)
        dd.line((x, 0, x + random.randint(-80, 80), 2400),
                fill=(random.randint(80, 110), random.randint(58, 78), random.randint(38, 52)),
                width=random.randint(2, 7))
    desk = desk.filter(ImageFilter.GaussianBlur(2))

    shadow = Image.new("RGBA", (paper.width + 60, paper.height + 60), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rectangle((30, 30, paper.width + 30, paper.height + 30), fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    angle = random.uniform(-4, 4)
    paper_rgba = paper.convert("RGBA").rotate(angle, expand=True, resample=Image.BICUBIC)
    shadow = shadow.rotate(angle, expand=True, resample=Image.BICUBIC)
    ox = (desk.width - paper_rgba.width) // 2 + random.randint(-60, 60)
    oy = (desk.height - paper_rgba.height) // 2 + random.randint(-60, 60)
    desk.paste(shadow, (ox + 14, oy + 22), shadow)
    desk.paste(paper_rgba, (ox, oy), paper_rgba)

    # Uneven room light, like a real phone photo.
    light = Image.new("L", desk.size, 0)
    ImageDraw.Draw(light).ellipse((-400, -600, 1600, 1800), fill=60)
    light = light.filter(ImageFilter.GaussianBlur(300))
    dark = Image.new("RGB", desk.size, (0, 0, 0))
    desk = Image.composite(desk, dark, Image.eval(light, lambda v: 195 + v))
    return desk


for index, (title, subtitle, lines) in enumerate(PAGES, 1):
    path = os.path.join(OUT, f"page_{index}.jpg")
    make_page(title, subtitle, lines, index).save(path, quality=90)
    print(path)
