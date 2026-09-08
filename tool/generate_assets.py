"""Reproducible, original concept merchandise illustrations (not official marks)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'products'
OUT.mkdir(parents=True, exist_ok=True)
S = 1000
BLUE = '#06386B'
GOLD = '#DDB764'
font_dir = Path('C:/Windows/Fonts')
def font(size, bold=False):
    return ImageFont.truetype(str(font_dir / ('arialbd.ttf' if bold else 'arial.ttf')), size)
def text(d, xy, value, size, fill, bold=False, anchor='mm'):
    d.text(xy, value, font=font(size, bold), fill=fill, anchor=anchor)
def shadow(im):
    mask = im.getchannel('A').filter(ImageFilter.GaussianBlur(19))
    sh = Image.new('RGBA', im.size, (5, 24, 46, 0)); sh.putalpha(mask.point(lambda a: int(a*.2)))
    result = Image.new('RGBA', im.size); result.alpha_composite(sh, (12, 26)); result.alpha_composite(im)
    return result
def shield(d, x, y, s):
    pts = [(x-.5*s,y-.48*s),(x+.5*s,y-.48*s),(x+.46*s,y+.14*s),(x+.24*s,y+.43*s),(x,y+.58*s),(x-.24*s,y+.43*s),(x-.46*s,y+.14*s)]
    d.polygon(pts, fill=GOLD, outline='#AB8035', width=max(1,int(s*.018)))
    inner = [(x+(a-x)*.85,y+(b-y)*.85) for a,b in pts]
    d.polygon(inner, fill=BLUE)
    d.line((x,y-.29*s,x,y+.17*s), fill=GOLD, width=max(2,int(s*.05)))
    d.line((x-.17*s,y-.14*s,x+.17*s,y-.14*s), fill=GOLD, width=max(2,int(s*.045)))
    text(d,(x,y+.34*s),'A',int(s*.19),GOLD,True)
def make(kind, id):
    im = Image.new('RGBA',(S,S)); d=ImageDraw.Draw(im)
    if kind=='pin':
        shield(d,500,455,480)
        d.line((270,225,700,225),fill='#FFF0B2',width=6)
        d.arc((272,225,725,735),-15,55,fill='#FFF3C5',width=4)
    elif kind=='shirt':
        pts=[(330,210),(230,250),(145,395),(277,466),(333,370),(310,755),(693,755),(670,370),(725,466),(855,395),(770,250),(670,210),(600,195),(565,228),(440,228),(400,195)]
        d.polygon(pts, fill='#FDFDFD' if id=='uniform' else BLUE, outline='#D0D5DB',width=3)
        d.polygon([(230,250),(145,395),(277,466),(333,370),(333,305)],fill=BLUE)
        d.polygon([(770,250),(855,395),(725,466),(670,370),(670,305)],fill=BLUE)
        d.polygon([(315,670),(688,670),(693,755),(310,755)],fill=BLUE)
        d.line((315,652,687,652),fill=GOLD,width=9)
        d.arc((393,145,605,270),0,180,fill=BLUE,width=22)
        d.arc((412,164,587,254),0,180,fill='#BBC7D2',width=6)
        d.line((341,349,333,641),fill='#E5E7EA',width=5)
        d.line((660,350,671,641),fill='#D8DDE3',width=4)
        d.line((355,727,651,727),fill='#235582',width=3)
        shield(d,590,346,65)
        text(d,(500,454),'ATENEO',57,BLUE if id=='uniform' else '#FFFFFF',True)
        text(d,(500,507),'DE DAVAO',24,BLUE if id=='uniform' else GOLD,True)
        text(d,(500,549),'UNIVERSITY',15,'#758897' if id=='uniform' else '#FFFFFF')
        if id=='uniform':
            d.polygon([(600,707),(836,707),(869,893),(755,907),(718,815),(697,904),(579,892)],fill='#092F56',outline='#1E4D76',width=3)
            d.line((602,723,833,723),fill='#386189',width=7)
            d.line((839,742,859,879),fill='#FAFAFA',width=12)
            shield(d,800,775,38)
    elif kind=='sling':
        # Individually drawn front/back straps with woven edge stitching.
        d.line([(355,157),(309,184),(463,713)],fill='#032347',width=88)
        d.line([(645,157),(687,184),(523,713)],fill=BLUE,width=88)
        d.arc((347,112,655,287),180,360,fill=BLUE,width=60)
        d.line([(275,185),(433,710)],fill='#577896',width=3)
        d.line([(720,185),(557,710)],fill='#50799F',width=3)
        left=Image.new('RGBA',(660,70)); ld=ImageDraw.Draw(left)
        text(ld,(330,36),'ATENEO DE DAVAO UNIVERSITY',23,'#FFFFFF',True)
        left=left.rotate(-73,expand=True,resample=Image.Resampling.BICUBIC)
        im.alpha_composite(left,(259,205))
        right=Image.new('RGBA',(620,70)); rd=ImageDraw.Draw(right)
        text(rd,(310,35),'COMPUTER STUDIES' if id=='cs' else 'ATENEO DE DAVAO',26,'#FFFFFF',True)
        right=right.rotate(73,expand=True,resample=Image.Resampling.BICUBIC)
        im.alpha_composite(right,(510,220))
        d=ImageDraw.Draw(im)
        d.rounded_rectangle((437,693,552,776),radius=12,fill='#182A3B',outline='#637280',width=4)
        d.rounded_rectangle((462,767,525,817),radius=8,fill='#ADB5BE',outline='#E7EBEE',width=5)
        d.arc((460,796,533,884),-100,230,fill='#BBC2C8',width=13)
        d.line((527,817,512,861),fill='#F5F7F8',width=6)
    elif kind=='case':
        d.rounded_rectangle((297,177,711,810),radius=38,fill='#D1DFEA',outline='#AABDCB',width=5)
        d.rounded_rectangle((306,184,700,800),radius=31,fill=BLUE)
        d.rounded_rectangle((325,265,681,773),radius=16,fill='#FEFFFF')
        d.rounded_rectangle((437,205,576,227),radius=9,fill='#BCCCD8')
        text(d,(503,309),'ATENEO DE DAVAO',23,BLUE,True)
        text(d,(503,339),'UNIVERSITY',15,'#748595')
        d.rounded_rectangle((419,385,588,560),radius=8,fill='#E8EDF2')
        d.ellipse((474,412,537,474),fill='#A5B6C5')
        d.rounded_rectangle((447,481,563,552),radius=30,fill='#A5B6C5')
        text(d,(504,605),'STUDENT NAME',22,BLUE,True)
        text(d,(504,642),'2026  •  COLLEGE',15,'#8495A6')
        for i in range(38):
            x=389+i*6; d.rectangle((x,689,x+(1 if i%3 else 3),725),fill='#445B6C')
        d.line((320,226,320,737),fill='#EAF5FD',width=4)
    elif kind=='ribbon':
        d.polygon([(393,420),(274,825),(413,770),(476,891),(566,502)],fill=BLUE)
        d.polygon([(573,426),(730,808),(590,768),(542,893),(443,502)],fill='#124C86')
        d.line((410,484,328,774),fill='#336494',width=5)
        for i in range(22):
            a=i*math.tau/22; x=500+math.cos(a)*126;y=375+math.sin(a)*126
            d.ellipse((x-61,y-61,x+61,y+61),fill='#12497F',outline='#23598F',width=3)
        d.ellipse((373,248,627,502),fill=BLUE,outline=GOLD,width=9)
        shield(d,500,370,118)
    elif kind=='caduceus':
        # Sculpted gold medical emblem, with layered specular strokes.
        for side in [-1,1]:
            for i in range(7):
                x=500+side*(80+i*27); y=333-i*17
                d.line([(500,419),(x,y),(x+side*54,y-113)],fill='#A97A30',width=31)
                d.line([(500,409),(x,y-5),(x+side*54,y-113)],fill='#E4C16D',width=23)
                d.line([(500,404),(x,y-9),(x+side*54,y-111)],fill='#F8DFA0',width=6)
        d.rounded_rectangle((485,240,517,797),radius=12,fill='#C69744')
        d.line((496,255,496,787),fill='#FCE4A4',width=9)
        d.ellipse((461,201,540,280),fill='#DCB65F',outline='#FBE5A4',width=5)
        for side in [-1,1]:
            points=[(500+side*math.sin(i*.11)*100,391+i*3.5) for i in range(105)]
            d.line(points,fill='#A7782F',width=30)
            d.line([(x-3,y-3) for x,y in points],fill='#E7C36C',width=23)
            d.line([(x-6,y-6) for x,y in points],fill='#FFE7A8',width=5)
    return shadow(im)

products={'pin':'pin','sling':'sling','uniform':'shirt','caduceus':'caduceus','case':'case','ribbon':'ribbon','cs':'sling','shirt':'shirt'}
images={}
for id,kind in products.items():
    images[id]=make(kind,id)
    images[id].resize((700,700),Image.Resampling.LANCZOS).save(OUT/f'{id}.png')
hero=Image.new('RGBA',(1200,1000))
hero.alpha_composite(images['uniform'].resize((940,940),Image.Resampling.LANCZOS).rotate(-8,expand=False),(80,-8))
hero.alpha_composite(images['sling'].resize((720,720),Image.Resampling.LANCZOS).rotate(19,expand=False),(495,210))
hero.alpha_composite(images['pin'].resize((380,380),Image.Resampling.LANCZOS).rotate(13,expand=False),(10,570))
hero.save(OUT/'hero.png')
print('Created 9 original concept illustrations in',OUT)
