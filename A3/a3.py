import sys 
import os
import numpy as np
import warp as wp
from PIL import Image
# print("\n".join(sys.argv))

def isArgSize():
    # print(len(sys.argv))
    if len(sys.argv) == 6:  # need to include py file as an arg so length is 6, not 5
        return True
    else:
        return False

def algType():
    if sys.argv[1] == "-s":
        # print("hit for -s")
        return "-s"
        # will add call to function specialized for this alg type 
    elif sys.argv[1] == "-n":
        # print("hit for -n")
        return "-n"
        # will add call to function specialized for this alg type 
    else:
        print("incorrect value for algType provided")
        print("Shutting down...")
        exit()
        # need to add warning here that there was an issue with this part of the cmd line args 

def kernSize():
    if int(sys.argv[2]) % 2 != 0 and int(sys.argv[2]) > 0: # ensure input is odd and a positive number
        # print("hit for: odd number")
        return int(sys.argv[2])
        # will add call to function specialized for this kern size 
    else:
        print("incorrect value for kernSize provided")
        print("Shutting down...")
        exit()
        # print("miss for: even number or negative")
        # need to add warning here that there was an issue with this part of the cmd line args 

def param():
    try:
        value = float(sys.argv[3])   # convert string to int
        if value == 0.0:
            value = 1.0
        return value
    except ValueError:
        print("incorrect value for param provided")
        print("Shutting down...")
        exit()


def inFileName():
    if os.path.isfile(sys.argv[4]):
        # print("hit for the file - it exists")
        return sys.argv[4]
    else: 
        print("incorrect value for inFileName provided")
        print("Shutting down...")
        exit()

def outFileName():
    return sys.argv[5]

        


def processArgs():
    """
    Function used to check arg size and arg parameters.
    
    - alg type: algType is either -s (sharpen) or -n (noise removal)
    - kernSize: kernSize is the kernel size - e.g. 3 for 3x3, 5 for 5x5, etc.. It must always be positive and odd.
    - param: param is the additional numerical parameter that the algorithm needs - e.g. the scaling value k for unsharp masking or sigma for the gaussian. If your algorithm doesn't need any additional parameters once it knows the kernel size, just pass some dummy value here (e.g. 0)
    - inFileName: inFileName is the name of the input image file
    - outFileName: outFileName is the name of the output image file

    Returns: algo choosen, k value, and p value
    """

    isArgs : bool = isArgSize()
    if isArgs == False:
        print("Arguments are incorrect: too many or too few were provided.")
        print("Shutting down...")
        exit()

    algo : str = algType()
    kernelSize : int = kernSize()
    k : int = param()
    fNameIn : str = inFileName()
    fNameOut : str = outFileName()

    return algo, kernelSize, k 

# load image with PIL 

def loadImg():
    """Returns image numpyarray and mode"""
    image = Image.open(sys.argv[4])
    print(image.mode)

    if image.mode == "L":
        imgMode = "L"
        print("GreyScale")
    elif image.mode == "RGBA":
        image = image.convert("RGB")
        imgMode = "RGB"
        print("RGBA --> RGB")
    else: 
        imgMode = "RGB"
        print("RGB")

    numpyArr = np.asarray(image, dtype='float32')
    print(numpyArr.shape)

    return numpyArr, imgMode

# Source - https://stackoverflow.com/questions/29731726/how-to-calculate-a-gaussian-kernel-matrix-efficiently-in-numpy
# Posted by clemisch, modified by community. See post 'Timeline' for change history
# Retrieved 2025-11-24, License - CC BY-SA 4.0
import numpy as np
   
def gaussianKernel(l, sig):
    """
    creates gaussian kernel with side length `l` and a sigma of `sig`
    """
    ax = np.linspace(-(l - 1) / 2., (l - 1) / 2., l)
    gauss = np.exp(-0.5 * np.square(ax) / np.square(sig))
    kernel = np.outer(gauss, gauss)
    return kernel / np.sum(kernel)

def create_kernel_denoising_greyScale(kernelSize, shape):
    """ 
    Kernel closur with the constants:
      - kernelSize
      - shape (image.shape) 
    contains the denoising function: denoising_greyScale
    """
    height, width = shape 
    radius = kernelSize // 2
    @wp.kernel  
    def denoising_greyScale(inputImage: wp.array(dtype=wp.float32, ndim=2),
                            outputImage: wp.array(dtype=wp.float32, ndim=2),
                            gWeightsWarp: wp.array(dtype=wp.float32, ndim=2) ):
        """
        Computes the convolution for removing noise from a grey scale image
        Args:
          - inputImage: warp array of the input image 
          - outputImage: warp array to store the return values of the new image
          - gWeightsWarp: gaussian weights array 
        """
        i, j = wp.tid()
        smoothedValue = 0.0

        # follows the 2d convolution from lecture 12 page 14: g(x, y) = ΣΣ w(i, j) * f(x + i, w + i)
        # where g(x, y) is the smoothed value 
        # w(i, j) is the weight form gaussian kernel
        # f(x + i, y + i) is the input image pixel at its positon (with offset calculated) 
        # for the following below: i --> offest_i = kernel_y - radius and j --> offset_j = kernel_x - radius 
        for kernel_y in range(kernelSize):
            for kernel_x in range(kernelSize):

                # handle the pixels withint he k x k window 
                offset_i = kernel_y - radius  #computes the offset from the center of the kernel 
                offset_j = kernel_x - radius 

                pixel_i = i + offset_i #computes the position of the pixel within the neigbourhood 
                pixel_j = j + offset_j 

                # handle boarder using the reflection statagy dicsussed in lecutre as it is the recomended approach 
                # need to handle both possitions pixel_i & pixel_j

                # height: for pixel_i --> bounds for pixels_i are witin range {0, height} anything outside is a boarder issue and must be refelcted  
                if pixel_i < 0:
                    pixel_i = -pixel_i   # just need the inverse, this is a simple flip when the value is negative 
                elif pixel_i >= height: 
                    # formula derived from lecture 12: using the reflection strategy for pixels outside the bottom of the image 
                    # forula reenforced from opencv guthub as well: https://github.com/opencv/opencv/blob/4.x/modules/core/src/opencl/copymakeborder.cl 
                    # Example for a 4x4 image:
                    # height = 4, valid row index's: [0, 1, 2, 3]
                    #        outside border index's: [4, 5, 6, 7, ...]

                    # for pixel_i = 5 which is two bellow the image border 
                    # reflection would occur as follows:
                    # 2 * height - pixel_i - 2 --> 2 * 4 - 5 - 2
                    # 8 - 5 - 2 --> 8 - 7
                    # reflected pixel = 1 


                    # Boundry would be 3 in this case
                    # since pixel 5 was two rows from the boundry its reflection should be two rows witin the boundry  
                    # the same logic can be applied for pixel 6 where its reflection would be 0
                    # this can be seen as: [4, 5, 6, 7, ...] pixel 6 is three rows outside the boundry
                    # and [0, 1, 2, [3]] pixel 0 is also three rows within the boundry 
                    # all valid reflections for this would be: 6 <-> 0, 5 <-> 1, 4 <-> 2 || 3 is the boundry therfore no valid reflection 
                    pixel_i = 2 * height - pixel_i - 2 
 

                #width: for pixel_j -> bounds for pixel_j are within the range {0, width}
                if pixel_j < 0:
                    pixel_j = -pixel_j
                elif pixel_j >= width:
                    pixel_j = 2 * width - pixel_j - 2 # same logic as above but for width boarder issues now 

                # now that we have the pixel positons (adjustments for border issues taken into account) we can get the pixels actually value 
                imagePixelValue = inputImage[pixel_i, pixel_j]

                # need the gaussian weights as well to figure out the smoothing values 
                gImageWeights = gWeightsWarp[kernel_y, kernel_x] 

                # Convlution averaging from lecture 12 pg: 14  --> calculating g(x, y) here [gaussian blurred value] for each kernel  
                smoothedValue += imagePixelValue * gImageWeights
        outputImage[i, j] = smoothedValue
    return denoising_greyScale


def create_kernel_denoising_colour(kernelSize, shape):
    height, width, colourChannels = shape
    radius = kernelSize // 2

    @wp.kernel
    def denoising_colour(inputImage: wp.array(dtype=wp.float32, ndim=3),
                         outputImage: wp.array(dtype=wp.float32, ndim=3),
                         gWeightsWarp: wp.array(dtype=wp.float32, ndim=2)):
        
        i, j, z = wp.tid()
        smoothedValue = 0.0 

        for kernel_y in range(kernelSize):
            for kernel_x in range(kernelSize):

                # handle the pixels withint he k x k window 
                offset_i = kernel_y - radius  #computes the offset from the center of the kernel 
                offset_j = kernel_x - radius 

                pixel_i = i + offset_i #computes the position of the pixel within the neigbourhood 
                pixel_j = j + offset_j 

                # handle boarder using the reflection statagy dicsussed in lecutre as it is the recomended approach 
                # need to handle both possitions pixel_i & pixel_j

                # height: for pixel_i --> bounds for pixels_i are witin range {0, height} anything outside is a boarder issue and must be refelcted  
                if pixel_i < 0:
                    pixel_i = -pixel_i
                elif pixel_i >= height: 
                    # formula derived from lecture 12: using the reflection strategy for pixels outside the bottom of the image 
                    # Example for a 4x4 image:
                    # height = 4, valid row index's: [0, 1, 2, 3]
                    #        outside border index's: [4, 5, 6, 7, ...]

                    # for pixel_i = 5 which is two bellow the image border 
                    # reflection would occur as follows:
                    # 2 * height - pixel_i - 2 --> 2 * 4 - 5 - 2
                    # 8 - 5 - 2 --> 8 - 7
                    # reflected pixel = 1 


                    # Boundry would be 3 in this case
                    # since pixel 5 was two rows from the boundry its reflection should be two rows witin the boundry  
                    # the same logic can be applied for pixel 6 where its reflection would be 0
                    # this can be seen as: [4, 5, 6, 7, ...] pixel 6 is three rows outside the boundry
                    # and [0, 1, 2, [3]] pixel 0 is also three rows within the boundry 
                    # all valid reflections for this would be: 6 <-> 0, 5 <-> 1, 4 <-> 2 || 3 is the boundry therfore no valid reflection 
                    pixel_i = 2 * height - pixel_i - 2 
 

                #width: for pixel_j -> bounds for pixel_j are within the range {0, width}
                if pixel_j < 0:
                    pixel_j = -pixel_j
                elif pixel_j >= width:
                    pixel_j = 2 * width - pixel_j - 2 # same logic as above but for width boarder issues now 

                # now that we have the pixel positons (adjustments for border issues taken into account) we can get the pixels actually value 
                imagePixelValue = inputImage[pixel_i, pixel_j, z]

                # need the gaussian weights as well to figure out the smoothing values 
                gImageWeights = gWeightsWarp[kernel_y, kernel_x] 

                # Convlution averaging from lecture 12 pg: 14  --> calculating g(x, y) here [gaussian blurred value] for each kernel  
                smoothedValue += imagePixelValue * gImageWeights
        outputImage[i, j, z] = smoothedValue
    return denoising_colour

def create_kernel_unsharp_masking_greyScale(kernelSize, shape, k):
    """
    Function used to compute unsharp masking using mean filtering. 
    Follows the following formulas: 
    f(x, y) is the original image 
    Creating the edge image: g(x, y) = f(x, y) - S(f(x, y)) 
    where S(f(x, y)) is the blurred version of the original image
    Creating the Unsharp Masking image: fUM(x, y) = f(x, y) + kg(x, y) 
    where g(x, y) is the edge image , k is the scaling constant (reasonable values lie between 0.2 and 0.7)
    
    """
    height, width = shape
    radius = kernelSize // 2

    @wp.kernel
    def unsharp_masking_blur_greyScale(inputImage: wp.array(dtype=wp.float32, ndim=2),
                                       blurBufferImage: wp.array(dtype=wp.float32, ndim=2), 
                                       gaussianWeightsWarp: wp.array(dtype=wp.float32, ndim=2)):
        """computes S(f(x, y)) --> the blurred image and write it to the output buffer array: blurBufferImage"""
        
        i, j = wp.tid()
        # blurredValue = 0.0
        # blurredMean = 0.0
        blurredValue = 0.0
        imagePixelValue = 0.0

        for kernel_y in range(kernelSize):
            for kernel_x in range(kernelSize):
                # handle the pixels withint he k x k window 
                # need offsets
                offset_i = kernel_y - radius  #computes the offset from the center of the kernel 
                offset_j = kernel_x - radius 

                # need pixel pos
                pixel_i = i + offset_i #computes the position of the pixel within the neigbourhood 
                pixel_j = j + offset_j 

                # handle edges for height and width 
                if pixel_i < 0:
                    pixel_i = -pixel_i
                elif pixel_i >= height:
                    pixel_i = 2 * height - pixel_i - 2

                if pixel_j < 0:
                    pixel_j = -pixel_j
                elif pixel_j >= width:
                    pixel_j = 2 * width - pixel_j - 2

                # calc blurred value from original image 
                # blurredValue += inputImage[pixel_i, pixel_j]
                imagePixelValue = inputImage[pixel_i, pixel_j]
                gImageWeights = gaussianWeightsWarp[kernel_y, kernel_x]

                
                blurredValue += imagePixelValue * gImageWeights


        # blurredMean = blurredValue * (1.0 / (float(kernelSize) * float(kernelSize)))
        # save to blur buffer warp array 
        blurBufferImage[i, j] = blurredValue

    @wp.kernel
    def unsharp_masking_edge_greyScale(inputImage: wp.array(dtype=wp.float32, ndim=2),
                                       blurBufferImage: wp.array(dtype=wp.float32, ndim=2),
                                       edgeBufferImage: wp.array(dtype=wp.float32, ndim=2)):
        """Computes the edge image based on the following formula: g(x, y) = f(x, y) - S(f(x, y))"""
        i, j = wp.tid()

        edgeBufferImage[i, j] = inputImage[i, j] - blurBufferImage[i, j]
        

    @wp.kernel
    def unsharp_masking_sharpen_greyScale(inputImage: wp.array(dtype=wp.float32, ndim=2), 
                                          edgeBufferImage: wp.array(dtype=wp.float32, ndim=2),
                                          outputImage: wp.array(dtype=wp.float32, ndim=2)):
        """Computes the unsharp masking image based on the following formula: fUM(x, y) = f(x, y) + k * g(x, y)"""
        i, j = wp.tid() 

        tempValue = inputImage[i, j] + (float(k) * edgeBufferImage[i, j])
        
        # used to deal with excessive overshots?
        if tempValue < 0.0:
            tempValue = 0.0
        elif tempValue > 255.0:
            tempValue = 255.0

        outputImage[i, j] = tempValue

    return unsharp_masking_blur_greyScale, unsharp_masking_edge_greyScale, unsharp_masking_sharpen_greyScale
    

def create_kernel_unsharp_masking_colour(kernelSize, shape, k):
    height, width, colourChannels = shape
    radius = kernelSize // 2
    
    @wp.kernel 
    def unsharp_masking_blur_colour(inputImage: wp.array(dtype=wp.float32, ndim=3),
                                    blurBufferImage: wp.array(dtype=wp.float32, ndim=3), 
                                    gWeightsWarp: wp.array(dtype=wp.float32, ndim=2)):
        i, j, z = wp.tid()
        smoothedvalue = 0.0 

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

                smoothedvalue += imagePixelValue * gImageWeights
        blurBufferImage[i, j, z] = smoothedvalue

    @wp.kernel 
    def unsharp_masking_edge_colour(inputImage: wp.array(dtype=wp.float32, ndim=3),
                                    blurBufferImage: wp.array(dtype=wp.float32, ndim=3),
                                    edgeBufferImage: wp.array(dtype=wp.float32, ndim=3)):
        i, j, z = wp.tid()
        edgeBufferImage[i, j, z] = inputImage[i, j, z] - blurBufferImage[i, j, z]

    @wp.kernel 
    def unsharp_masking_sharpen_colour(inputImage: wp.array(dtype=wp.float32, ndim=3), 
                                       edgeBufferImage: wp.array(dtype=wp.float32, ndim=3), 
                                       outputImage: wp.array(dtype=wp.float32, ndim=3)):     
        i, j, z = wp.tid()
        tempValue = inputImage[i, j, z] + (float(k) * edgeBufferImage[i, j, z])

        if tempValue < 0.0:
            tempValue = 0.0
        elif tempValue > 255.0:
            tempValue = 255.0

        outputImage[i, j, z] = tempValue
        
    return unsharp_masking_blur_colour, unsharp_masking_edge_colour, unsharp_masking_sharpen_colour


def main():
    algo, kernelSize, k = processArgs()
    numpyArr, imgMode = loadImg()
    print(k)

    # init warp and set device type
    wp.init()
    device = "cpu"

    if algo == "-n":
        gWeights = gaussianKernel(kernelSize, float(k)).astype(np.float32)

        inWarpImage = wp.from_numpy(numpyArr, dtype=wp.float32, device=device)
        outWarpImage = wp.zeros(shape=numpyArr.shape, dtype=wp.float32, device=device)
        gWarpWeights = wp.from_numpy(gWeights, dtype=wp.float32, device=device)


        if imgMode == "L":
            # need to load image and convert from PIL to NumPy --> this step is done within the within the loadImg function 
            # Convert this to warp arrays

            # print(numpyArr.shape)

            # create and call closure: args gaussian weights, kernel size, sigma, shape 
            denoising_kernel = create_kernel_denoising_greyScale(kernelSize, numpyArr.shape)

            wp.launch(
                kernel = denoising_kernel,
                dim = numpyArr.shape,
                inputs = [inWarpImage, outWarpImage, gWarpWeights],
                device = device
            )

            # launch warp kernel 
            # convert warp output to PIL image 

        elif imgMode == "RGB":
            # same as above with the addition of a third dim for RBG -->shape is now H, W, C

            denoising_kernel = create_kernel_denoising_colour(kernelSize, numpyArr.shape)

            wp.launch(
                kernel = denoising_kernel,
                dim = numpyArr.shape,
                inputs = [inWarpImage, outWarpImage, gWarpWeights],
                device=device
            )
    elif algo == "-s":

        # this avoids the mix up between k and sigma (used in UM and gaussian blur)
        customSigma = kernelSize / 3
        gWeights = gaussianKernel(kernelSize, float(customSigma)).astype(np.float32)

        # need to do unsharp masking now 
        # convert to warp arrays

        inWarpImage = wp.from_numpy(numpyArr, dtype=wp.float32, device=device)
        blurBufferWarp = wp.zeros(shape=numpyArr.shape, dtype=wp.float32, device=device)
        gWarpWeights = wp.from_numpy(gWeights, dtype=wp.float32, device=device)

        edgeBufferWarp = wp.zeros(shape=numpyArr.shape, dtype=wp.float32, device=device)
        outWarpImage = wp.zeros(shape=numpyArr.shape, dtype=wp.float32, device=device)


        if imgMode == "L":
            blurKernel, edgeKernel, sharpenKernel = create_kernel_unsharp_masking_greyScale(kernelSize, numpyArr.shape, k)
           
            wp.launch(
                kernel = blurKernel,
                dim = numpyArr.shape,
                inputs = [inWarpImage, blurBufferWarp, gWarpWeights],
                device=device
            )

            wp.launch(
                kernel = edgeKernel,
                dim = numpyArr.shape,
                inputs = [inWarpImage, blurBufferWarp, edgeBufferWarp],
                device=device 
            )

            wp.launch(
                kernel = sharpenKernel,
                dim = numpyArr.shape,
                inputs = [inWarpImage, edgeBufferWarp, outWarpImage],
                device=device
            )

        elif imgMode == "RGB":
            blurKernel, edgeKernel, sharpenKernel = create_kernel_unsharp_masking_colour(kernelSize, numpyArr.shape, k)
            
            wp.launch(
                kernel = blurKernel,
                dim = numpyArr.shape,
                inputs = [inWarpImage, blurBufferWarp, gWarpWeights],
                device=device
            )

            wp.launch(
                kernel = edgeKernel,
                dim = numpyArr.shape,
                inputs = [inWarpImage, blurBufferWarp, edgeBufferWarp],
                device=device 
            )

            wp.launch(
                kernel = sharpenKernel,
                dim = numpyArr.shape,
                inputs = [inWarpImage, edgeBufferWarp, outWarpImage],
                device=device
            )




    numpyOutArr = outWarpImage.numpy()
    imageOut = Image.fromarray(np.uint8(numpyOutArr))
    imageOut.save(outFileName())


if __name__ == "__main__":
    main()
