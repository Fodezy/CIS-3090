import sys
import os
import subprocess

def run_test(input_image, output_image, kernel_size, sigma, description):
    """Run Gaussian blur test and return success status"""
    print(f"\n{'='*60}")
    print(f"Test: {description}")
    print(f"Input: {input_image}")
    print(f"Output: {output_image}")
    print(f"Parameters: kernel_size={kernel_size}, sigma={sigma}")
    print(f"{'='*60}")
    
    # Check if input image exists
    if not os.path.exists(input_image):
        print(f"ERROR: Input image not found: {input_image}")
        return False
    
    # Run the algorithm
    cmd = [
        sys.executable,
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "a3.py"),
        "-n",
        str(kernel_size),
        str(sigma),
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
    """Run all Gaussian blur tests"""
    print("="*60)
    print("GAUSSIAN BLUR TEST SUITE")
    print("="*60)
    
    # Get the input and output directory paths
    parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    input_dir = os.path.join(parent_dir, "imgs")
    output_dir = os.path.join(parent_dir, "outImgs")
    
    results = []
    
    # Test Case 1: Noisy Image
    test_image = os.path.join(input_dir, "gdorleans_noise.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test1_noisy_sigma0.5.jpg"),
                5, 0.5,
                "Test 1a: Noisy image, sigma=0.5 (minimal blur)"
            ),
            "Test 1a: Minimal blur"
        ))
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test1_noisy_sigma1.0.jpg"),
                5, 1.0,
                "Test 1b: Noisy image, sigma=1.0 (moderate blur)"
            ),
            "Test 1b: Moderate blur"
        ))
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test1_noisy_sigma2.0.jpg"),
                5, 2.0,
                "Test 1c: Noisy image, sigma=2.0 (strong blur)"
            ),
            "Test 1c: Strong blur"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 2: Image with Fine Details
    test_image = os.path.join(input_dir, "schwyz_townhall.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test2_finedetails.jpg"),
                5, 1.0,
                "Test 2: Image with fine details"
            ),
            "Test 2: Fine details smoothing"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 3: High-Noise Image
    for noise_file in ["noise_1.jpg", "noise_2.jpg"]:
        test_image = os.path.join(input_dir, noise_file)
        if os.path.exists(test_image):
            results.append((
                run_test(
                    test_image,
                    os.path.join(output_dir, f"blur_test3_highnoise_{noise_file}"),
                    5, 2.0,
                    f"Test 3: High-noise image ({noise_file})"
                ),
                f"Test 3: High-noise image"
            ))
            break
    
    # Test Case 4: RGB Image (rgbImg.jpg)
    # This is an RGB image - tests RGB color channel processing
    test_image = os.path.join(input_dir, "rgbImg.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test4_rgb.jpg"),
                5, 1.0,
                "Test 4: RGB image (rgbImg.jpg)"
            ),
            "Test 4: RGB image"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 5: RGBA Image (rgbaImg.png)
    # This is an RGBA image - tests RGBA to RGB conversion and processing
    # The code automatically converts RGBA to RGB before processing
    test_image = os.path.join(input_dir, "rgbaImg.png")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test5_rgba.png"),
                5, 1.0,
                "Test 5: RGBA image (rgbaImg.png) - converted to RGB"
            ),
            "Test 5: RGBA image (converted to RGB)"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 6: Kernel Size Variation
    test_image = os.path.join(input_dir, "gdorleans_noise.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test6_kernel3.jpg"),
                3, 1.0,
                "Test 6a: Kernel size 3x3"
            ),
            "Test 6a: Kernel size 3"
        ))
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test6_kernel7.jpg"),
                7, 1.0,
                "Test 6b: Kernel size 7x7"
            ),
            "Test 6b: Kernel size 7"
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