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
python3 a3.py -s 5 0.5 imgs/schwyz_townhall.jpg outImgs/schwyz_townhall_k0.5.jpg

# Gaussian blur
python3 a3.py -s 5 1.0 imgs/gdorleans_noise.jpg outimgs/gdorleans_highnoise.jpg 
```

### Supported Image Formats
- Grayscale images (mode "L")
- RGB images (mode "RGB")
- RGBA images (automatically converted to RGB)

**Why RGBA images are converted to RGB:**
RGBA images contain four channels: Red, Green, Blue, and Alpha (transparency). The implementation converts RGBA to RGB for the following reasons:

1. **Kernel Design Limitation**: The Warp kernels are designed to handle either:
   - Grayscale images: 2D arrays (height × width)
   - RGB images: 3D arrays (height × width × 3 channels)
   There is no kernel implementation for 4-channel RGBA arrays.

2. **Alpha Channel Irrelevance**: The alpha channel represents transparency information, which is not relevant for image processing operations like sharpening (unsharp masking) or blurring (Gaussian blur). These operations work on color intensity values, not transparency.

3. **Implementation Simplicity**: By converting to RGB, the code only needs to handle two cases (grayscale and RGB) instead of three, simplifying the implementation and reducing code complexity.

4. **Standard Conversion**: When PIL converts RGBA to RGB using `image.convert("RGB")`, it composites the image against a white background, which is the standard approach for handling transparency in image processing pipelines.

5. **Output Format Compatibility**: Most image formats used for processed output (like JPEG) don't support transparency anyway, so converting to RGB ensures compatibility with standard output formats.

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

```

#### Test Output

- Test results are printed to the console with pass or fail indicators
- Processed output images are saved to `outImgs` directory
- Each test case produces a separate output image for visual inspection
- A summary is provided at the end showing passed/failed tests

#### Test Structure

The tests are separated by image-processing technique
- **test_unsharp_masking.py**: Tests unsharp masking with different k values and kernel sizes
- **test_gaussian_blur.py**: Tests Gaussian blur with different sigma values and kernel sizes

#### Input and Output Files

All input images are located in the `imgs/` directory, and all output images are saved to the `outImgs/` directory.

#### Experimental Design: Controlled and Varied Variables

To systematically validate the algorithms, we used a controlled testing approach where certain variables were kept constant while others were intentionally varied:

**Variables Kept Constant (Controlled Variables):**
- **Kernel size**: Most tests use a kernel size of 5x5, which provides a good balance between processing quality and computational efficiency
- **k_param**: Most tests use a k_param of 0.5 for unsharp masking and a sigma of 1.0 for Gaussian blur, both moderate intensities
- **Border handling**: All tests use the same reflection padding strategy
- **Device**: All tests run on CPU using Warp's CPU backend

#### Image Format Verification

A utility script `check_image_formats.py` is provided to verify the actual format and mode of test images:

```bash
python3 tests/check_image_formats.py
```

**Why this test was added:**
Previously, we were unsure of the pixel mode of the images. We wanted to compare RGB and RGBA images, but initially had to rely on the supplier's information to determine the format. By using PIL, we were able to verify the true image format, which reports the actual pixel mode (L, RGB, or RGBA). This verification step is particularly important for Test Cases 3 and 4, as it ensures that we are testing color channel processing accurately, rather than making assumptions based on filenames.

#### Image Analysis Utility

A utility script, `analyze_images.py` is provided in the `tests/` directory to verify effects of image processing algorithms:

```bash
python3 tests/analyze_images.py
```

**Purpose of this utility:**
This script performs quantitative analysis on input and output image pairs to measure the actual effects of the algorithms. It calculates several key metrics:
- **Mean brightness change**: Difference in average pixel intensity between input and output
- **Standard deviation change**: Change in pixel value variance, indicating edge enhancement (increase) or smoothing (decrease)
- **Mean absolute difference**: Average pixel-wise difference, indicating overall change magnitude
- **Maximum difference**: Largest single-pixel change, useful for detecting artifacts

The script analyzes all test cases for both unsharp masking and Gaussian blur algorithms, providing statistical validation to the "Actual Results" section in this report.

### 3.1 Unsharp Masking Test Cases

#### Test Case 1: Noise Image with Varying k Parameter
**Input:** `noise_1.jpg` - Noisy image for testing different sharpening strengths
**Output Files:**
- `unsharp_test1_noise1_k0.3.jpg` - k=0.3 (subtle sharpening)
- `unsharp_test1_noise1_k0.5.jpg` - k=0.5 (moderate sharpening)
- `unsharp_test1_noise1_k0.7.jpg` - k=0.7 (strong sharpening)
- `unsharp_test1_noise1_k1.5.jpg` - k=1.5 (very strong sharpening)

**Purpose of Test Case:**
This test systematically evaluates how the k parameter affects sharpening intensity. By testing a range of k values (0.3, 0.5, 0.7, 1.5), we can observe how sharpening strength changes in the output and identify optimal values for different use cases.
**Expected Result:** We expect each image to show progressively stronger sharpening, with enhanced edges and improved detail visibility. However, at the extreme k value of 1.5, the filter is likely to add excessive contrast near edges (making bright regions too bright and dark regions too dark) which can actually make the image appear less sharp than at 0.7. We also expect this extreme case to produce halo artifacts that blur true edges and overwhelm fine detail.
**Actual Result:**
- k=0.3 and k=0.5 produce very subtle changes (mean absolute difference: 2.29 and 4.11), indicating natural-looking, gentle sharpening
- k=0.7 shows moderate change (mean absolute difference: 5.63) with increased standard deviation (2.77), demonstrating stronger edge enhancement
- k=1.5 produces moderate change overall (mean absolute difference: 10.18) but with significantly higher maximum difference (121 vs 73 for k=0.7), indicating the presence of halo artifacts and excessive contrast enhancement at edges
- Standard deviation increases progressively with k values (0.89, 1.82, 2.77, 5.80), confirming that higher k values enhance edge contrast more dramatically
- The extreme k value of 1.5 does indeed produce artifacts as expected, making the image appear less sharp than at k=0.7

#### Test Case 2: Noise Image with Varying Kernel Sizes
**Input:** `noise_2.jpg` - Noisy image for testing different kernel sizes
**Output Files:**
- `unsharp_test2_noise2_kernel3.jpg` - Kernel size 3x3
- `unsharp_test2_noise2_kernel5.jpg` - Kernel size 5x5
- `unsharp_test2_noise2_kernel7.jpg` - Kernel size 7x7
- `unsharp_test2_noise2_kernel9.jpg` - Kernel size 9x9

**Purpose of Test Case:**
This test evaluates the algorithm's behavior with different kernel sizes, ensuring the implementation correctly handles various kernel dimensions. It also helps us understand how kernel size affects the spatial extent of the sharpening effect.
**Expected Result:** Smaller kernel sizes should produce very fine, local sharpening; enhancing tiny details and textures while creating crisp, tight edges. A 5×5 kernel serves as a standard reference for comparison. A 7×7 kernel is expected to produce more global sharpening effects with wider edge detection, while a 9×9 kernel may introduce halos and create a broad, soft blur, making it a less desirable choice.
**Actual Result:**
- Kernel size 3x3 produces very subtle, localized sharpening (mean absolute difference: 3.07), enhancing fine details with minimal overall change
- Kernel size 5x5 shows subtle change (mean absolute difference: 4.90), serving as a good reference point for moderate sharpening
- Kernel sizes 7x7 and 9x9 produce moderate changes (mean absolute difference: 5.52 and 6.05), demonstrating broader, more global sharpening effects
- Standard deviation increases with kernel size (1.01, 2.03, 2.66, 3.21), confirming that larger kernels produce wider edge detection and enhancement
- All kernel sizes maintain image quality, with the 9x9 kernel showing only slightly more effect than 7x7, suggesting diminishing returns for very large kernels

#### Test Case 3: RGBA to RGB Conversion
**Input:** `bird_rgba.png` - RGBA image that will be converted to RGB format
**Output File:** `unsharp_test3_bird_rgb.png`
**Purpose of Test Case:**
To verify that the algorithm correctly handles RGBA images by converting them to RGB and processing the resulting channels properly.
**Expected Result:** The RGBA image should be converted to RGB with little to no visible change in quality, as the source image is already high quality.
**Actual Result:**
- The RGBA image was successfully converted to RGB (mode changed from RGBA to RGB)
- The conversion and processing produced a very subtle change (mean absolute difference: 2.19), confirming minimal visible alteration
- Standard deviation increased slightly (0.77), indicating gentle edge enhancement
- The algorithm correctly processed all three RGB channels uniformly
- No color artifacts or misalignment were introduced
- The output maintains proper RGB color representation with high quality preserved

#### Test Case 4: Already Sharp Image
**Input:** `dog_rgb.jpg` - Already sharp, high-detail image
**Output File:** `unsharp_test4_dog_rgb.jpg`
**Purpose of Test Case:**
Although similar to the previous test, this case double-checks the algorithm's behavior using an image that is not RGBA. It evaluates how unsharp masking performs on an image that is already sharp, ensuring the program does not introduce unexpected artifacts by over-sharpening.
**Expected Result:** Minimal visible change, with a slight possibility of reduced quality if the algorithm attempts to sharpen an already sharp image.
**Actual Result:**
- The algorithm produced a moderate change (mean absolute difference: 8.85), which is more noticeable than the bird_rgba test
- Standard deviation increased significantly (5.37), indicating that sharpening was applied and edge contrast was enhanced
- The RGB color channels were processed correctly (mode remained RGB)
- The statistics indicate that the image became sharper, which may be quantitatively accurate. However, subjectively, at first glance the image appears blurrier; similar to the effect sometimes seen in Photoshop when applying sharpening to certain images.
- No major artifacts were introduced (maximum difference: 61), maintaining reasonable image quality

### 3.2 Gaussian Blur Test Cases

#### Test Case 1: Noisy Image with Varying Sigma Parameter
**Input:** `gdorleans_noise.jpg` - High-quality black and white image
**Output Files:**
- `blur_test1_gdorleans_sigma0.5.jpg` - σ=0.5 (minimal blur)
- `blur_test1_gdorleans_sigma1.0.jpg` - σ=1.0 (moderate blur)
- `blur_test1_gdorleans_sigma2.0.jpg` - σ=2.0 (strong blur)

**Purpose of Test Case:**
This test evaluates the primary parameter of Gaussian blur: its ability to reduce noise. By testing different sigma values (0.5, 1.0, 2.0), we can observe how increasing sigma affects blur strength, noise reduction, and identify optimal values for various noise levels.
**Expected Result:** Noise should decrease noticeably as sigma increases, with higher values producing a stronger blur than the previous setting. Edges will become softer and harder to distinguish, creating a smooth, stylized background.
**Actual Result:**
- Noise reduction is clearly visible, with progressive smoothing as sigma increases (mean absolute difference: 8.74, 14.27, 17.55)
- Standard deviation decreases significantly with higher sigma values (-2.85, -6.79, -8.64), confirming effective noise reduction and smoothing
- The blurring effect becomes stronger at each sigma level, with σ=2.0 producing a strong, noticeable blur (mean absolute difference: 17.55)
- Edges become progressively softer, with maximum differences increasing (77, 130, 149), indicating more extensive smoothing at higher sigma values
- The algorithm successfully reduces noise while maintaining overall image structure, with no artifacts introduced
- The black and white image shows clear, progressive blurring effects that create a smooth, stylized appearance

#### Test Case 2: Noisy Image with Varying Kernel Sizes
**Input:** `gdorleans_noise.jpg` - Same High-quality black and white image, used to test different kernel sizes
**Output Files:**
- `blur_test2_gdorleans_kernel3.jpg` - Kernel size 3x3
- `blur_test2_gdorleans_kernel5.jpg` - Kernel size 5x5
- `blur_test2_gdorleans_kernel7.jpg` - Kernel size 7x7
- `blur_test2_gdorleans_kernel9.jpg` - Kernel size 9x9

**Purpose of Test Case:**
This test examines the algorithm's behavior with different kernel sizes, ensuring the implementation correctly handles various kernel dimensions. It also helps clarify how kernel size influences the spatial extent of the blurring effect.
**Expected Result:** Smaller kernel sizes will produce a light blur that preserves fine details, while larger kernel sizes will generate a stronger, wider, and smoother blur.
**Actual Result:**
- Kernel size 3x3 produces moderate blurring (mean absolute difference: 12.70), preserving more fine details compared to larger kernels
- Kernel sizes 5x5, 7x7, and 9x9 produce similar moderate blurring effects (mean absolute difference: 14.27, 14.40, 14.40), indicating that beyond kernel size 5, the effect plateaus
- Standard deviation reduction is consistent across larger kernel sizes (-5.49, -6.79, -6.94, -6.95), showing effective noise reduction
- The blurring effect does not scale linearly with kernel size; kernel 3 shows less blur, but kernels 5, 7, and 9 produce nearly identical results
- All kernel sizes successfully reduce noise while maintaining image structure, with larger kernels providing slightly more smoothing

#### Test Case 3: RGBA to RGB Conversion
**Input:** `bird_rgba.png` - RGBA image that will be converted to RGB format
**Output File:** `blur_test3_bird_rgb.png`
**Purpose of Test Case:**
To verify that the algorithm is compatible with RGBA images by correctly converting them to RGB and processing the resulting channels.
**Expected Result:** After conversion, the RGB version of the image should appear noticeably blurrier than the black-and-white images. Because the original RGBA image contains rich color variation and high detail, the Gaussian blur produces a more dramatic smoothing effect.
**Actual Result:**
- The RGBA image was successfully converted to RGB (mode changed from RGBA to RGB)
- The blurring effect is very subtle (mean absolute difference: 3.44), which is less dramatic than expected given the rich color variation in the original image
- Standard deviation decreased slightly (-0.77), indicating gentle smoothing
- The algorithm correctly processed all three RGB channels uniformly
- No color artifacts or misalignment were introduced
- The output maintains proper RGB color representation, though the blur effect is more subtle than in the black-and-white tests

#### Test Case 4: High-Detail Image
**Input:** `dog_rgb.jpg` - High-detail, already sharp image
**Output File:** `blur_test4_dog_rgb.jpg`
**Purpose of Test Case:**
This test evaluates how Gaussian blur impacts high-detail images. It highlights the trade-off between reducing noise and preserving important details, helping determine appropriate blur parameters for different image types.
**Expected Result:** The image should appear blurred, with reduced fine details while maintaining its overall structure. The effect is expected to look more dramatic than in other tests due to the presence of text and intricate details.
**Actual Result:**
- The blurring effect is strong and noticeable (mean absolute difference: 17.14), demonstrating significant smoothing of fine details
- Standard deviation decreased substantially (-7.28), confirming effective noise reduction and detail smoothing
- The RGB color channels were processed correctly (mode remained RGB)
- The blurring effect is more dramatic than in other tests, as expected due to the presence of text and intricate details in the original image
- Fine details are significantly reduced while major features remain recognizable
- The maximum difference (135) indicates extensive smoothing across the image, creating a uniform blur effect

---

## 4. Kernel Implementation with Warp API

Both algorithms are implemented as **Warp closures**. Each `create_kernel_*` factory captures the kernel size, image shape, and tuning parameters, then returns one or more `@wp.kernel` functions that can be launched with `wp.launch`. This approach keeps the kernels stateless and allows Gaussian weights to be pre-computed once per run.

### Gaussian blur (`-n`)
The denoising path generates a single kernel that operates on the entire image tensor (either `H×W` for grayscale or `H×W×3` for RGB). The kernel indexes pixels using `wp.tid()`, slides a `kernelSize×kernelSize` window across the image, applies reflection padding, and accumulates the weighted sum using the precomputed Gaussian weights passed in as a third argument.

```218:283:A3/a3.py
def create_kernel_denoising_colour(kernelSize, shape):
    ...
    @wp.kernel
    def denoising_colour(inputImage: wp.array(dtype=wp.float32, ndim=3),
                         outputImage: wp.array(dtype=wp.float32, ndim=3),
                         gWeightsWarp: wp.array(dtype=wp.float32, ndim=2)):
        i, j, z = wp.tid()
        smoothedValue = 0.0
        for kernel_y in range(kernelSize):
            for kernel_x in range(kernelSize):
                offset_i = kernel_y - radius
                offset_j = kernel_x - radius
                pixel_i = i + offset_i
                pixel_j = j + offset_j
                if pixel_i < 0:
                    pixel_i = -pixel_i
                elif pixel_i >= height:
                    pixel_i = 2 * height - pixel_i - 2
                if pixel_j < 0:
                    pixel_j = -pixel_j
                elif pixel_j >= width:
                    pixel_j = 2 * width - pixel_j - 2
                imagePixelValue = inputImage[pixel_i, pixel_j, z]
                gImageWeights = gWeightsWarp[kernel_y, kernel_x]
                smoothedValue += imagePixelValue * gImageWeights
        outputImage[i, j, z] = smoothedValue
```

**Important points:**
- The input image and Gaussian weights are transferred to the Warp device once using `wp.from_numpy(...)`, allowing reuse across multiple kernel launches
- Reflection padding is implemented inline, ensuring every thread has valid neighbor pixels even at the borders.
- Using `dim=numpyArr.shape` spawns one thread per pixel (and per channel for RGB), enabling the entire convolution to run in parallel.

### Unsharp masking (`-s`)
Unsharp masking implements a three-pass sharpening pipeline. First, the image is blurred. Second, the blurred image is subtracted from the original to create an edge map. Third, a scaled version of the edges is added back to the input. Each step is implemented as its own kernel, returned as a tuple so they can be launched sequentially while sharing intermediate Warp buffers.

```285:373:A3/a3.py
def create_kernel_unsharp_masking_greyScale(kernelSize, shape, k):
    ...
    @wp.kernel
    def unsharp_masking_blur_greyScale(...):
        ...
                gImageWeights = gaussianWeightsWarp[kernel_y, kernel_x]
                blurredValue += imagePixelValue * gImageWeights
        blurBufferImage[i, j] = blurredValue

    @wp.kernel
    def unsharp_masking_edge_greyScale(...):
        i, j = wp.tid()
        edgeBufferImage[i, j] = inputImage[i, j] - blurBufferImage[i, j]

    @wp.kernel
    def unsharp_masking_sharpen_greyScale(...):
        i, j = wp.tid()
        tempValue = inputImage[i, j] + (float(k) * edgeBufferImage[i, j])
        if tempValue < 0.0:
            tempValue = 0.0
        elif tempValue > 255.0:
            tempValue = 255.0
        outputImage[i, j] = tempValue
```
**Colour Path Version:**
To keep the design small and composable while supporting both grayscale and RGB images, we leverage Warp's parallel execution without writing any explicit loops outside the kernels themselves. The colour path (`create_kernel_unsharp_masking_colour`) follows the same structure as the grayscale version, but extends the tensors to three dimensions so that each thread also iterates over the channel index `z`.

During execution:
1. Gaussian weights are precomputed with `sigma = kernelSize / 3` to ensure the blur stage matches the sharpening kernel size.  
2. Warp buffers (`blurBufferWarp`, `edgeBufferWarp`, `outWarpImage`) are allocated with the same shape as the input, keeping all intermediate data on the device so each kernel reads and writes the appropriate array.  
3. The blur kernel is launched first, followed by the edge kernel, and then the sharpen kernel. Warp automatically schedules each launch over the full image dimensions.  

---

## 5. Border Handling

### 5.1 Reflection Strategy

Both algorithms use **reflection (mirror) padding** (option 3 in lecture 12) to handle border pixels. This strategy reflects pixels at the image boundaries, creating a mirror effect that maintains approximate continuity.

### 5.2 Purpose of Reflection Padding

1. **Continuity**: Reflection maintains approximate continuity at boundaries, which is important for convolution operations. This prevents artifacts that would occur with zero-padding.

2. **No Artifacts**: Unlike zero-padding, reflection doesn't introduce dark borders or edge artifacts that would be visible in the output.

3. **Natural Appearance**: The reflected pixels are similar to the actual image content, making the border handling less noticeable.

### 5.3 Implementation Details

#### For Top and Left Borders (Negative Indices):
```python
if pixel_i < 0:
    pixel_i = -pixel_i  # Simple reflection: -1 -> 1, -2 -> 2, etc.
if pixel_j < 0:
    pixel_j = -pixel_j
```

**Example:**
For a 4×4 image with valid indices [0, 1, 2, 3]:
- Index -1 reflects to index 1
- Index -2 reflects to index 2
- Index -3 reflects to index 3

This creates a mirror effect at the top and left edges using reflected neighbors from below and the right.

#### For Bottom and Right Borders (Indices >= Image Size):
```python
elif pixel_i >= height:
    pixel_i = 2 * height - pixel_i - 2
elif pixel_j >= width:
    pixel_j = 2 * width - pixel_j - 2
```
This formula uses reflected neighbors from above and left and ensures indices beyond the boundary are reflected back into the valid range.

**Mathematical Concept of Reflection:**
For an image of size `N` with valid indices [0, 1, 2, ..., N-1]:
- Boundary is at index `N-1`
- Index `N` (one beyond boundary) should reflect to `N-2`
- Index `N+1` should reflect to `N-3`
- General formula: `reflected_index = 2 * N - original_index - 2`

**Example for height = 4:**
- Index 4 (outside): `2*4 - 4 - 2 = 2`
- Index 5 (outside): `2*4 - 5 - 2 = 1`
- Index 6 (outside): `2*4 - 6 - 2 = 0`

This creates a mirror effect at the bottom and right edges.

---

## 6. Conclusion

This assignment provided an in-depth understanding of the algorithms behind Gaussian blur for image smoothing and unsharp masking for image sharpening. With this knowledge, photo editing no longer feels like magic; we can now understand exactly what happens behind the scenes. Furthermore, we can recognize when a camera or software has applied these operations and anticipate potential effects such as halos or unwanted artifacts. Most importantly, we now have the ability to edit and enhance our own images using this program, without needing to purchase commercial photo-editing software.