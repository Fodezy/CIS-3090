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
    
    # Test Case 1: gdorleans_noise with varying k parameter (0.5, 1.0, 2.0)
    # Default: kernel_size=5
    test_image = os.path.join(input_dir, "gdorleans_noise.jpg")
    if os.path.exists(test_image):
        for sigma in [0.5, 1.0, 2.0]:
            results.append((
                run_test(
                    test_image,
                    os.path.join(output_dir, f"blur_test1_gdorleans_sigma{sigma}.jpg"),
                    5, sigma,
                    f"Test 1: gdorleans_noise, sigma={sigma} (kernel_size=5)"
                ),
                f"Test 1: gdorleans_noise, sigma={sigma}"
            ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 2: gdorleans_noise with varying kernel sizes (3, 5, 7, 9)
    # Default: k parameter=1.0
    test_image = os.path.join(input_dir, "gdorleans_noise.jpg")
    if os.path.exists(test_image):
        for kernel_size in [3, 5, 7, 9]:
            results.append((
                run_test(
                    test_image,
                    os.path.join(output_dir, f"blur_test2_gdorleans_kernel{kernel_size}.jpg"),
                    kernel_size, 1.0,
                    f"Test 2: gdorleans_noise, kernel_size={kernel_size} (sigma=1.0)"
                ),
                f"Test 2: gdorleans_noise, kernel_size={kernel_size}"
            ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 3: bird_rgba converting to RGB
    # Default: kernel_size=5, k parameter=1.0
    test_image = os.path.join(input_dir, "bird_rgba.png")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test3_bird_rgb.png"),
                5, 1.0,
                "Test 3: bird_rgba converting to RGB (kernel_size=5, sigma=1.0)"
            ),
            "Test 3: bird_rgba to RGB"
        ))
    else:
        print(f"WARNING: Test image not found: {test_image}")
    
    # Test Case 4: dog_rgb - see how it blurs high detailed image
    # Default: kernel_size=5, k parameter=1.0
    test_image = os.path.join(input_dir, "dog_rgb.jpg")
    if os.path.exists(test_image):
        results.append((
            run_test(
                test_image,
                os.path.join(output_dir, "blur_test4_dog_rgb.jpg"),
                5, 1.0,
                "Test 4: dog_rgb - high detailed image (kernel_size=5, sigma=1.0)"
            ),
            "Test 4: dog_rgb (high detail)"
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