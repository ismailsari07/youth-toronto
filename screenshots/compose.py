#!/usr/bin/env python3
"""App Store slides (1.4.0) from the raw simulator shots of take.sh.

    python3 screenshots/compose.py --raw screenshots/out --fonts <dir> --out <dir> [--lang en] [--sheet]

<dir> for --fonts holds InterDisplay-Bold.ttf, InterDisplay-SemiBold.ttf, Inter-Regular.ttf and
Inter-SemiBold.ttf (Inter 4.0, OFL: github.com/rsms/inter/releases). Inter stands in for SF Pro, which
Apple doesn't license for this. Writes <out>/<lang>/01.png … 10.png at 1320×2868, plus
<out>/<lang>/sheet.png with --sheet.

The design is the 1.0.x set's, measured from its PNGs: mint gradient (navy on 01 and 10), a two-line
headline and a subtitle near the top, a black iPhone frame below them, cut off by the bottom edge. Two
smaller, overlapping phones on 07 and 10. Slide 03 draws the three widgets (no phone). Images stay out
of git: screenshots/out/ is ignored.
"""

import argparse
import glob
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1320, 2868
RAW_W, RAW_H = 1320, 2868

LIGHT = dict(top=(238, 245, 241), bottom=(216, 233, 224), head=(15, 74, 57), sub=(75, 107, 96))
DARK = dict(top=(14, 26, 43), bottom=(15, 54, 46), head=(255, 255, 255), sub=(185, 199, 211))

# One phone at scale 1: the frame's box on the canvas and its parts, in pixels.
FRAME_W, BEZEL_X, BEZEL_Y = 1020, 26, 28
SCREEN_W = FRAME_W - 2 * BEZEL_X
SCREEN_H = round(SCREEN_W * RAW_H / RAW_W)
FRAME_H = SCREEN_H + 2 * BEZEL_Y
R_OUTER, R_SCREEN = 150, 122
ISLAND_W, ISLAND_H, ISLAND_TOP = 277, 82, 30
BEZEL = (11, 15, 20)

# (lang) → slide number → (headline lines, subtitle lines)
CAPTIONS = {
    'en': {
        1: (['Prayer times', 'from Diyanet'], ["Times from Türkiye's Presidency", 'of Religious Affairs']),
        2: (['Notified at', 'athan time'], ['Choose the prayers you want', 'to be notified for']),
        3: (['Prayer times on', 'your Home Screen'], ['Home Screen and', 'Lock Screen widgets']),
        4: (['Iqamah and', "Jumu'ah times"], ['Know exactly when', 'the congregation prays']),
        5: (['Monthly', 'prayer times'], ['Athan and iqamah', 'for the days ahead']),
        6: (['News from', 'your mosque'], ['Announcements and photos', 'from the mosque']),
        7: (['Community', 'and events'], ['Programmes, details', 'and reminders']),
        8: (['Support', 'your mosque'], ['Donate securely', 'in a few taps']),
        9: (['Marriage and', 'funeral services'], ["Reach the mosque's", 'services easily']),
        10: (['English, Türkçe,', 'Français'], ['Light and dark themes']),
    },
    'tr': {
        1: (['Namaz vakitleri', 'Diyanet’ten'], ['Türkiye Diyanet İşleri', 'Başkanlığı vakitleriyle']),
        2: (['Ezan vaktinde', 'bildirim'], ['Bildirim almak istediğiniz', 'vakitleri seçin']),
        3: (['Vakitler', 'ana ekranınızda'], ['Ana ekran ve', 'kilit ekranı widget’ları']),
        4: (['Cemaat ve', 'Cuma vakitleri'], ['Cemaatle namazın saatini', 'her zaman bilin']),
        5: (['Aylık', 'namaz vakitleri'], ['Önümüzdeki günlerin', 'ezan ve cemaat saatleri']),
        6: (['Camimizden', 'haberler'], ['Caminin duyuruları', 've fotoğrafları']),
        7: (['Cemaat ve', 'etkinlikler'], ['Programlar, ayrıntılar', 've hatırlatmalar']),
        8: (['Caminize', 'destek olun'], ['Birkaç dokunuşla', 'güvenle bağış yapın']),
        9: (['Evlilik ve', 'cenaze hizmetleri'], ['Cami hizmetlerine', 'kolayca ulaşın']),
        10: (['Türkçe, English,', 'Français'], ['Açık ve koyu tema']),
    },
    'fr': {
        1: (['Horaires de prière', 'de la Diyanet'], ['Les horaires de la Présidence', 'des affaires religieuses de Türkiye']),
        2: (['Une notification', 'à l’heure de l’adhan'], ['Choisissez vos prières']),
        3: (['Les horaires sur', 'votre écran d’accueil'], ['Widgets pour l’écran d’accueil', 'et l’écran verrouillé']),
        4: (['Heures de l’iqama', 'et de la Joumou’a'], ['Sachez exactement quand', 'la communauté prie']),
        5: (['Horaires', 'du mois'], ['Adhan et iqama', 'des prochains jours']),
        6: (['Nouvelles de', 'votre mosquée'], ['Annonces et photos', 'de la mosquée']),
        7: (['Communauté', 'et événements'], ['Programmes, détails', 'et rappels']),
        8: (['Soutenez', 'votre mosquée'], ['Donnez en toute sécurité', 'en quelques touches']),
        9: (['Mariage et', 'services funéraires'], ['Accédez facilement aux', 'services de la mosquée']),
        10: (['Français, English,', 'Türkçe'], ['Thèmes clair et sombre']),
    },
}

# Widget slide: names, clock texts and labels per language, as the 1.4.0 widget shows them.
WIDGET = {
    'en': dict(label='NEXT PRAYER', names=['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
               times=['6:08 AM', '7:37 AM', '1:07 PM', '3:57 PM', '6:26 PM', '7:45 PM'],
               athan='Athan 3:57 PM', iqamah='Iqamah 4:15 PM', lock='Asr · 3:57 PM'),
    'tr': dict(label='SIRADAKİ NAMAZ', names=['İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'],
               times=['06:08', '07:37', '13:07', '15:57', '18:26', '19:45'],
               athan='Ezan 15:57', iqamah='Cemaat 16:15', lock='İkindi · 15:57'),
    'fr': dict(label='PROCHAINE PRIÈRE', names=['Fajr', 'Lever du soleil', 'Dhohr', 'Asr', 'Maghrib', 'Icha'],
               times=['6 h 08', '7 h 37', '13 h 07', '15 h 57',
                      '18 h 26', '19 h 45'],
               athan='Adhan 15 h 57', iqamah='Iqama 16 h 15', lock='Asr · 15 h 57'),
}

# Slide → which raw shots, which palette, and the layout.
SLIDES = {
    1: ('dark', 'phone', ['prayer_light']),
    2: ('light', 'phone', ['notifications']),
    3: ('light', 'widgets', []),
    4: ('light', 'phone', ['times']),
    5: ('light', 'phone', ['monthly']),
    6: ('light', 'phone', ['news']),
    7: ('light', 'two', ['community', 'event']),
    8: ('light', 'phone', ['donate']),
    9: ('light', 'phone', ['marriage']),
    10: ('dark', 'two', ['language', 'prayer_dark']),
}


class Fonts:
    def __init__(self, folder):
        self.folder = folder

    def get(self, name, size):
        return ImageFont.truetype(os.path.join(self.folder, f'{name}.ttf'), round(size))


def gradient(top, bottom):
    img = Image.new('RGB', (1, H))
    for y in range(H):
        t = y / (H - 1)
        img.putpixel((0, y), tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img.resize((W, H))


def tracked_width(font, text, tracking):
    return font.getlength(text) + tracking * (len(text) - 1)


def draw_tracked(draw, xy, text, font, fill, tracking, anchor='ls'):
    """Text with letter spacing that keeps the font's kerning: each glyph sits where the
    untracked prefix ends, plus the tracking so far."""
    x, y = xy
    if anchor[0] == 'm':
        x -= tracked_width(font, text, tracking) / 2
    elif anchor[0] == 'r':
        x -= tracked_width(font, text, tracking)
    for i, ch in enumerate(text):
        draw.text((x + font.getlength(text[:i]) + tracking * i, y), ch, font=font, fill=fill, anchor='l' + anchor[1])


def caption(canvas, fonts, palette, head, sub):
    """Headline (cap top at 196, baselines 113 apart) and subtitle (baselines 62 apart), centred.
    A headline line wider than 1000 px shrinks the whole block, as on the 1.0.x set."""
    draw = ImageDraw.Draw(canvas)
    size = 110.0
    while True:
        font = fonts.get('InterDisplay-Bold', size)
        if max(tracked_width(font, l, -0.0245 * size) for l in head) <= 1000 or size < 70:
            break
        size -= 2
    k = size / 110
    cap = font.getbbox('H', anchor='ls')
    base = 196 - cap[1]  # cap top at 196
    for i, line in enumerate(head):
        draw_tracked(draw, (W / 2, base + i * 113 * k), line, font, palette['head'], -0.0245 * size, 'ms')
    sfont = fonts.get('Inter-Regular', 46)
    sbase = base + (len(head) - 1) * 113 * k + 99 * k
    for i, line in enumerate(sub):
        draw_tracked(draw, (W / 2, sbase + i * 62), line, sfont, palette['sub'], -1.0, 'ms')


def rounded_mask(size, radius, ss=4):
    w, h = size
    m = Image.new('L', (w * ss, h * ss), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * ss - 1, h * ss - 1], radius=radius * ss, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def shadow(canvas, box, radius, scale):
    x0, y0, x1, y1 = box
    blur, dy, alpha = 60 * scale, 40 * scale, 0.286
    pad = int(blur * 3)
    layer = Image.new('L', (x1 - x0 + 2 * pad, y1 - y0 + 2 * pad), 0)
    ImageDraw.Draw(layer).rounded_rectangle([pad, pad, pad + x1 - x0, pad + y1 - y0], radius=radius, fill=round(255 * alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    black = Image.new('RGB', layer.size, (0, 0, 0))
    canvas.paste(black, (x0 - pad, y0 - pad + round(dy)), layer)


def phone(canvas, raw, x, y, scale=1.0):
    fw, fh = round(FRAME_W * scale), round(FRAME_H * scale)
    shadow(canvas, (x, y, x + fw, y + fh), round(R_OUTER * scale), scale)
    canvas.paste(Image.new('RGB', (fw, fh), BEZEL), (x, y), rounded_mask((fw, fh), round(R_OUTER * scale)))
    sw, sh = round(SCREEN_W * scale), round(SCREEN_H * scale)
    sx, sy = x + round(BEZEL_X * scale), y + round(BEZEL_Y * scale)
    screen = raw.convert('RGB').resize((sw, sh), Image.LANCZOS)
    canvas.paste(screen, (sx, sy), rounded_mask((sw, sh), round(R_SCREEN * scale)))
    iw, ih = round(ISLAND_W * scale), round(ISLAND_H * scale)
    canvas.paste(Image.new('RGB', (iw, ih), (0, 0, 0)), (sx + (sw - iw) // 2, sy + round(ISLAND_TOP * scale)),
                 rounded_mask((iw, ih), ih // 2))


def widget_card(canvas, box, top, bottom, radius=72, diagonal=False):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    shadow(canvas, box, radius, 0.6)
    card = Image.new('RGB', (w, h))
    px = card.load()
    for yy in range(h):
        for xx in range(w) if diagonal else [0]:
            t = ((xx / w) * 0.45 + (yy / h) * 0.55) if diagonal else yy / h
            c = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
            if diagonal:
                px[xx, yy] = c
            else:
                for x2 in range(w):
                    px[x2, yy] = c
    canvas.paste(card, (x0, y0), rounded_mask((w, h), radius))


def widgets(canvas, fonts, lang):
    t = WIDGET[lang]
    d = ImageDraw.Draw(canvas)
    navy_top, navy_bottom = (48, 58, 75), (28, 39, 56)
    grey, white = (205, 211, 220), (255, 255, 255)
    label = fonts.get('Inter-SemiBold', 36)
    name = fonts.get('InterDisplay-Bold', 72)
    count = fonts.get('InterDisplay-SemiBold', 88)
    small = fonts.get('Inter-Regular', 42)
    row = fonts.get('Inter-Regular', 44)
    rowb = fonts.get('Inter-SemiBold', 44)

    def next_block(x, y, w, countdown):
        draw_tracked(d, (x + 60, y + 93), t['label'], label, grey, 4.5)
        d.text((x + 60, y + 200), t['names'][3], font=name, fill=white, anchor='ls')
        d.text((x + 60, y + 302), countdown, font=count, fill=white, anchor='ls')
        d.text((x + 60, y + 392), t['athan'], font=small, fill=grey, anchor='ls')
        d.text((x + 60, y + 441), t['iqamah'], font=small, fill=grey, anchor='ls')
        d.rounded_rectangle([x + 60, y + 483, x + w - 62, y + 495], radius=6, fill=(38, 47, 62))
        d.rounded_rectangle([x + 60, y + 483, x + 92, y + 495], radius=6, fill=(93, 202, 148))

    # Medium widget: next prayer on the left, the day's times on the right, the current one green.
    widget_card(canvas, (60, 1060, 1260, 1624), navy_top, navy_bottom)
    next_block(60, 1060, 600, '2:39:18')
    for i in range(6):
        base = 1060 + 122 + i * 70
        current = i == 2
        if current:
            d.rounded_rectangle([687, base - 50, 1201, base + 16], radius=18, fill=(11, 117, 79))
        f = rowb if current else row
        colour = white if current else (220, 225, 232)
        d.text((713, base), t['names'][i], font=f, fill=colour, anchor='ls')
        d.text((1173, base), t['times'][i], font=f, fill=colour, anchor='rs')
    # Small widget.
    widget_card(canvas, (60, 1700, 640, 2275), navy_top, navy_bottom)
    next_block(60, 1700, 580, '2:43:05')
    # Lock Screen style card.
    widget_card(canvas, (680, 1700, 1260, 2275), (160, 214, 208), (46, 100, 136), diagonal=True)
    big = fonts.get('InterDisplay-Bold', 150)
    draw_tracked(d, (970, 1700 + 255), '9:41', big, (242, 248, 248), -6, 'ms')
    d.text((770, 1700 + 355), t['lock'], font=fonts.get('InterDisplay-SemiBold', 44), fill=(242, 248, 248), anchor='ls')
    d.text((770, 1700 + 445), '2:42:55', font=fonts.get('InterDisplay-Bold', 80), fill=(242, 248, 248), anchor='ls')


def load_raw(raw_dir, lang, shot):
    found = glob.glob(os.path.join(raw_dir, lang, f'*_{shot}.png'))
    if not found:
        raise SystemExit(f'missing raw shot {lang}/{shot} in {raw_dir}')
    img = Image.open(found[0])
    if img.size != (RAW_W, RAW_H):
        raise SystemExit(f'{found[0]} is {img.size}, not {RAW_W}×{RAW_H}')
    return img


def slide(n, lang, raw_dir, fonts):
    mode, layout, shots = SLIDES[n]
    palette = DARK if mode == 'dark' else LIGHT
    canvas = gradient(palette['top'], palette['bottom'])
    head, sub = CAPTIONS[lang][n]
    caption(canvas, fonts, palette, head, sub)
    if layout == 'phone':
        phone(canvas, load_raw(raw_dir, lang, shots[0]), 150, 729)
    elif layout == 'two':
        # As the 1.0.x language slide: the first phone behind on the left, the second in front.
        phone(canvas, load_raw(raw_dir, lang, shots[0]), 40, 760, 0.6765)
        phone(canvas, load_raw(raw_dir, lang, shots[1]), 600, 930, 0.6765)
    else:
        widgets(canvas, fonts, lang)
    return canvas


def sheet(paths, out):
    thumbs = [Image.open(p).convert('RGB').resize((330, 717), Image.LANCZOS) for p in paths]
    s = Image.new('RGB', (5 * 330 + 6 * 16, 2 * 717 + 3 * 16), (255, 255, 255))
    for i, t in enumerate(thumbs):
        s.paste(t, (16 + (i % 5) * 346, 16 + (i // 5) * 733))
    s.save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--raw', required=True)
    ap.add_argument('--fonts', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--lang', action='append')
    ap.add_argument('--sheet', action='store_true')
    a = ap.parse_args()
    fonts = Fonts(a.fonts)
    for lang in a.lang or ['en', 'tr', 'fr']:
        folder = os.path.join(a.out, lang)
        os.makedirs(folder, exist_ok=True)
        paths = []
        for n in range(1, 11):
            p = os.path.join(folder, f'{n:02d}.png')
            slide(n, lang, a.raw, fonts).save(p, optimize=True)
            paths.append(p)
            print(p)
        if a.sheet:
            sheet(paths, os.path.join(folder, 'sheet.png'))


if __name__ == '__main__':
    main()
