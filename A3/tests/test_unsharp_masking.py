import sys
import os
import subprocess

def run_test(input_image, output_image, kernel_size, k_param, description):
    """Run unsharp masking test and return success status"""
    print(f"\n{'='*60}")
    print(f"Test: {description}")
    print(f"Input: {input_image}")
    print(f"Output: {output_image}")
    print(f"Parameters: kernel_size={kernel_size}, k={k_param}")
    print(f"{'='*60}")
    
    # Check if input image exists
    if not os.path.exists(input_image):
        print(f"ERROR: Input image not found: {input_image}")
        return False
    
    # Run the algorithm
    cmd = [
        sys.executable,
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "a3.py"),
        "-s",
        str(kernel_size),
        str(k_param),
        input_image,
        output_image
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        # Check if output image was created
        if os.path.exists(output_image):
            print(f"SUCCESS: Output image created: {output_image}")
            return True
        else:
            print(f"FAILED: Output image not created")
            return False
    # Syntax or runtime errors from the called script
    except subprocess.CalledProcessError as e:
        print(f"FAILED: Command failed with error:")
        print(f"  {e.stderr}")
        return False
    # Unexpected errors, such as cmd is malformed or denied permissions
    except Exception as e:
        print(f"FAILED: Unexpected error: {e}")
        return False

def main():
    """Run all unsharp masking tests"""
    print("="*60)
    print("UNSHARP MASKING TEST SUITE")
    print("="*60)
    
    # Get the input and output directory paths
    parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    input_dir = os.path.join(parent_dir, "imgs")
    output_dir = os.path.join(parent_dir, "outImgs")
    
    results = []
    
    # Test Case 1: Slightly Blurry Image
    test_image = os.path.join(input_dir, "schwyz_townhall.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "unsharp_test1_blurry_k0.2.jpg"),
                5, 0.2,
                "Test 1a: Slightly blurry image, k=0.2 (subtle sharpening)"
            ),
            "Test 1a: Subtle sharpening"
        ))
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "unsharp_test1_blurry_k0.5.jpg"),
                5, 0.5,
                "Test 1b: Slightly blurry image, k=0.5 (moderate sharpening)"
            ),
            "Test 1b: Moderate sharpening"
        ))
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "unsharp_test1_blurry_k0.7.jpg"),
                5, 0.7,
                "Test 1c: Slightly blurry image, k=0.7 (strong sharpening)"
            ),
            "Test 1c: Strong sharpening"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 2: High-Contrast Image
    # Note: dog_rgb.jpg - format can be checked with check_image_formats.py
    # The name suggests RGB, but the code handles both RGB and RGBA
    test_image = os.path.join(input_dir, "dog_rgb.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "unsharp_test2_highcontrast.jpg"),
                5, 0.5,
                "Test 2: High-contrast image with details (dog_rgb.jpg)"
            ),
            "Test 2: High-contrast image"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 3: RGB Image (rgbImg.jpg)
    # This is an RGB image - tests RGB color channel processing
    test_image = os.path.join(input_dir, "rgbImg.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "unsharp_test3_rgb.jpg"),
                5, 0.5,
                "Test 3: RGB image (rgbImg.jpg)"
            ),
            "Test 3: RGB image"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 4: RGBA Image (rgbaImg.png)
    # This is an RGBA image - tests RGBA to RGB conversion and processing
    # The code automatically converts RGBA to RGB before processing
    test_image = os.path.join(input_dir, "rgbaImg.png")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "unsharp_test4_rgba.png"),
                5, 0.5,
                "Test 4: RGBA image (rgbaImg.png) - converted to RGB"
            ),
            "Test 4: RGBA image (converted to RGB)"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 5: Parameter Testing - Different kernel sizes
    test_image = os.path.join(input_dir, "schwyz_townhall.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "unsharp_test5_kernel3.jpg"),
                3, 0.5,
                "Test 5a: Kernel size 3x3"
            ),
            "Test 5a: Kernel size 3"
        ))
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "unsharp_test5_kernel7.jpg"),
                7, 0.5,
                "Test 5b: Kernel size 7x7"
            ),
            "Test 5b: Kernel size 7"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Print summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    passed = sum(1 for result, _ in results if result)
    total = len(results)
    print(f"Passed: {passed}/{total}")
    
    for result, name in results:
        status = "PASS" if result else "FAIL"
        print(f"  {status}: {name}")
    
    print(f"\nOutput images saved to: {output_dir}")
    return 0 if passed == total else 1

if __name__ == "__main__":
    sys.exit(main())