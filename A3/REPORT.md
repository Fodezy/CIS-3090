# Assignment 3 Report: GPGPU Image Processing with Nvidia Warp

## 1. Information for Running the Code

### Command-Line Usage

Executable Command:
```
python3 a3.py algType kernSize param inFileName outFileName
```

**Arguments:**
- `algType`: Algorithm type selection
  - `-s`: Unsharp masking (sharpening)
  - `-n`: Gaussian blur (denoising)
- `kernSize`: Kernel size (must be an odd positive integer, e.g., 3, 5, 7)
- `param`: Algorithm-specific parameter
  - For `-s` (unsharp masking): Sharpening strength `k` (typically 0.2-0.7 for more sharpening)
  - For `-n` (Gaussian blur): Sigma value for Gaussian kernel (typically 0.5-3.0 for more blur)
- `inFileName`: Path to input image file
- `outFileName`: Path to output image file

### Example Commands

```bash
# Unsharp masking
python3 a3.py -s 5 0.5 input.jpg output.jpg

# Gaussian blur
python3 a3.py -n 5 2.0 input.jpg output.jpg
```

### Supported Image Formats
- Grayscale images (mode "L")
- RGB images (mode "RGB")
- RGBA images (automatically converted to RGB)

### Execution Environment
- **Device:** CPU (no GPU required)
- **Warp API:** Uses Warp's CPU backend for parallel processing
- The code explicitly sets `device = "cpu"` in the main function

---

## 2. Implemented Algorithms

### 2.1 Unsharp Masking (`-s`)

Unsharp masking is a sharpening technique that enhances edges by subtracting a blurred version of the image from the original and adding it back with a scaling factor.

**Mathematical Foundation:**
The algorithm consists of three steps:

1. **Blur the original image** using Gaussian blur:
   - `S(f(x,y))` = Gaussian blurred version of `f(x,y)`

2. **Extract the edge image** by subtracting the blurred image from the original:
   - `g(x,y) = f(x,y) - S(f(x,y))`
   - This captures high-frequency components (edges)

3. **Apply sharpening** by adding the edge image back with a scaling factor:
   - `f_UM(x,y) = f(x,y) + k * g(x,y)`
   - Where `k` is the sharpening strength parameter (typically 0.2-0.7)

**Why Unsharp Masking:**
- Effectively enhances edges and fine details
- Provides control over sharpening strength via parameter `k`
- Widely used in photography and image processing
- Produces natural-looking sharpening when used with appropriate parameters

**Implementation Details:**
- Uses Gaussian blur with sigma = `kernelSize / 3` for the blurring step
- Three separate kernel passes: blur, edge extraction, and sharpening
- Each pass processes all pixels including borders

### 2.2 Gaussian Blur (`-n`)

Gaussian blur is a denoising technique that applies a Gaussian-weighted convolution to smooth the image and reduce noise.

**Mathematical Foundation:**
The algorithm applies a weighted average of neighboring pixels, where weights follow a Gaussian distribution:

- `g(x,y) = ΣΣ w(i,j) * f(x+i, y+j)`

Where:
- `w(i,j)` are Gaussian weights based on distance from the center pixel
- The Gaussian weight is: `w(i,j) = exp(-(i² + j²) / (2σ²))`
- `σ` (sigma) is the standard deviation parameter that controls the blur amount

**Why Gaussian Blur:**
- Effective for noise reduction
- Smooth, natural-looking blur
- Preserves image structure while reducing high-frequency noise
- Standard technique in image processing

**Implementation Details:**
- Gaussian kernel is pre-computed using the provided sigma parameter
- Single kernel pass performs the convolution
- All pixels including borders are processed

---

## 3. Test Cases and Validation

### Running the Test Suite

Automated test scripts are provided in the `tests/` directory to validate algorithm correctness. The test suite includes comprehensive tests for both algorithms with various parameters and image types.

#### Executable Commands

```bash
# Unsharp masking tests
python3 tests/test_unsharp_masking.py

# Gaussian blur tests
python3 tests/test_gaussian_blur.py

# Check image formats
python3 tests/check_image_formats.py
```

#### Test Output

- Test results are printed to the console with pass or fail indicators
- Processed output images are saved to `outImgs` directory
- Each test case produces a separate output image for visual inspection
- A summary is provided at the end showing passed/failed tests

#### Test Structure

The tests are seperated by image-processing technique
- **test_unsharp_masking.py**: Tests unsharp masking with different k values and kernel sizes
- **test_gaussian_blur.py**: Tests Gaussian blur with different sigma values and kernel sizes

#### Image Format Verification

A utility script `check_image_formats.py` is provided to verify the actual format and mode of test images:

```bash
python3 tests/check_image_formats.py
```

**Why this test was added:**
Previously, we were unsure of the pixel mode of the images. We wanted to compare RGB and RGBA images, but initially had to rely on the supplier’s information to determine the format. By using PIL, we were able to verify the true image format, which reports the actual pixel mode (L, RGB, or RGBA). This verification step is particularly important for Test Cases 3 and 4, as it ensures that we are testing color channel processing accurately, rather than making assumptions based on filenames.

