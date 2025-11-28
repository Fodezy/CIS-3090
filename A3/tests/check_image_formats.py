import sys
import os
from PIL import Image

def check_image_format(image_path):
    if not os.path.exists(image_path):
        print(f"ERROR: Image not found: {image_path}")
        return None
    
    try:
        image = Image.open(image_path)
        print(f"Image: {image_path}")
        print(f"  Format: {image.format}")
        print(f"  Mode: {image.mode}")
        print(f"  Size: {image.size}")
        print(f"  Shape would be: {image.size[1]} x {image.size[0]} x {len(image.mode)}")
        return image.mode
    except Exception as e:
        print(f"ERROR: Could not open image {image_path}: {e}")
        return None

def main():
    print("="*60)
    print("IMAGE FORMAT CHECKER")
    print("="*60)
    
    # Get the directory paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(script_dir)
    imgs_dir = os.path.join(parent_dir, "imgs")
    
    images_to_check = [
        os.path.join(imgs_dir, "dog_rgb.jpg"),
        os.path.join(imgs_dir, "bird_rgba.png"),
        os.path.join(imgs_dir, "rgbImg.jpg"),
        os.path.join(imgs_dir, "rgbaImg.png"),
        os.path.join(imgs_dir, "schwyz_townhall.jpg"),
        os.path.join(imgs_dir, "gdorleans_noise.jpg"),
    ]
    
    print("\n")
    for image_path in images_to_check:
        check_image_format(image_path)
        print()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())