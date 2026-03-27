import os
from PIL import Image, ImageDraw

def add_rounded_corners(im, rad):
    circle = Image.new('L', (rad * 2, rad * 2), 0)
    draw = ImageDraw.Draw(circle)
    draw.ellipse((0, 0, rad * 2 - 1, rad * 2 - 1), fill=255)
    
    alpha = Image.new('L', im.size, 255)
    w, h = im.size
    
    alpha.paste(circle.crop((0, 0, rad, rad)), (0, 0))
    alpha.paste(circle.crop((0, rad, rad, rad * 2)), (0, h - rad))
    alpha.paste(circle.crop((rad, 0, rad * 2, rad)), (w - rad, 0))
    alpha.paste(circle.crop((rad, rad, rad * 2, rad * 2)), (w - rad, h - rad))
    
    im.putalpha(alpha)
    return im

def main():
    img_path = r"c:\Users\hp\JDEED\flutter_application_1\assets\app_icon.jpg"
    out_path = r"c:\Users\hp\JDEED\flutter_application_1\assets\app_icon_rounded.png"
    
    if not os.path.exists(img_path):
        print("Image not found: " + img_path)
        return
        
    im = Image.open(img_path).convert("RGBA")
    
    # 20% of smallest dimension for radius
    radius = int(min(im.size) * 0.20)
    
    im_rounded = add_rounded_corners(im, radius)
    im_rounded.save(out_path, "PNG")
    print("Saved rounded icon to " + out_path)

if __name__ == "__main__":
    main()
