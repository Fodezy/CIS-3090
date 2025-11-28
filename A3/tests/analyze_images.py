from PIL import Image
import os
import numpy as np

# Get paths relative to the A3 directory (parent of tests/)
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out_dir = os.path.join(parent_dir, "outImgs")
imgs_dir = os.path.join(parent_dir, "imgs")

def analyze_image_pair(input_path, output_path, test_name):
    """Analyze input and output images to describe the effect"""
    if not os.path.exists(input_path) or not os.path.exists(output_path):
        return f"{test_name}: Files not found"
    
    input_img = Image.open(input_path)
    output_img = Image.open(output_path)
    
    input_arr = np.array(input_img.convert('RGB'))
    output_arr = np.array(output_img.convert('RGB'))
    
    # Calculate statistics
    input_mean = input_arr.mean()
    output_mean = output_arr.mean()
    input_std = input_arr.std()
    output_std = output_arr.std()
    
    # Calculate difference
    diff = np.abs(input_arr.astype(float) - output_arr.astype(float))
    mean_diff = diff.mean()
    max_diff = diff.max()
    
    result = f"{test_name}:\n"
    result += f"  Input size: {input_img.size}, mode: {input_img.mode}\n"
    result += f"  Output size: {output_img.size}, mode: {output_img.mode}\n"
    result += f"  Mean brightness change: {output_mean - input_mean:.2f}\n"
    result += f"  Std deviation change: {output_std - input_std:.2f}\n"
    result += f"  Mean absolute difference: {mean_diff:.2f}\n"
    result += f"  Max difference: {max_diff:.2f}\n"
    
    # Qualitative assessment
    if mean_diff < 5:
        result += "  Effect: Very subtle/minimal change\n"
    elif mean_diff < 15:
        result += "  Effect: Moderate change\n"
    else:
        result += "  Effect: Strong/noticeable change\n"
    
    return result

# Analyze unsharp masking tests
print("="*60)
print("UNSHARP MASKING TEST RESULTS")
print("="*60)

# Test 1: Varying k parameter
for k in [0.3, 0.5, 0.7, 1.5]:
    input_path = os.path.join(imgs_dir, "noise_1.jpg")
    output_path = os.path.join(out_dir, f"unsharp_test1_noise1_k{k}.jpg")
    print(analyze_image_pair(input_path, output_path, f"Test 1: k={k}"))

# Test 2: Varying kernel sizes
for kernel in [3, 5, 7, 9]:
    input_path = os.path.join(imgs_dir, "noise_2.jpg")
    output_path = os.path.join(out_dir, f"unsharp_test2_noise2_kernel{kernel}.jpg")
    print(analyze_image_pair(input_path, output_path, f"Test 2: kernel={kernel}"))

# Test 3: bird_rgba
input_path = os.path.join(imgs_dir, "bird_rgba.png")
output_path = os.path.join(out_dir, "unsharp_test3_bird_rgb.png")
print(analyze_image_pair(input_path, output_path, "Test 3: bird_rgba"))

# Test 4: dog_rgb
input_path = os.path.join(imgs_dir, "dog_rgb.jpg")
output_path = os.path.join(out_dir, "unsharp_test4_dog_rgb.jpg")
print(analyze_image_pair(input_path, output_path, "Test 4: dog_rgb"))

print("\n" + "="*60)
print("GAUSSIAN BLUR TEST RESULTS")
print("="*60)

# Test 1: Varying sigma
for sigma in [0.5, 1.0, 2.0]:
    input_path = os.path.join(imgs_dir, "gdorleans_noise.jpg")
    output_path = os.path.join(out_dir, f"blur_test1_gdorleans_sigma{sigma}.jpg")
    print(analyze_image_pair(input_path, output_path, f"Test 1: sigma={sigma}"))

# Test 2: Varying kernel sizes
for kernel in [3, 5, 7, 9]:
    input_path = os.path.join(imgs_dir, "gdorleans_noise.jpg")
    output_path = os.path.join(out_dir, f"blur_test2_gdorleans_kernel{kernel}.jpg")
    print(analyze_image_pair(input_path, output_path, f"Test 2: kernel={kernel}"))

# Test 3: bird_rgba
input_path = os.path.join(imgs_dir, "bird_rgba.png")
output_path = os.path.join(out_dir, "blur_test3_bird_rgb.png")
print(analyze_image_pair(input_path, output_path, "Test 3: bird_rgba"))

# Test 4: dog_rgb
input_path = os.path.join(imgs_dir, "dog_rgb.jpg")
output_path = os.path.join(out_dir, "blur_test4_dog_rgb.jpg")
print(analyze_image_pair(input_path, output_path, "Test 4: dog_rgb"))

