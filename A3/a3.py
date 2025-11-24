import sys 
import os
import numpy as np
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
        value = int(sys.argv[3])   # convert string to int
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
    """

    isArgs : bool = isArgSize()
    if isArgs == False:
        print("Arguments are incorrect: too many or too few were provided.")
        print("Shutting down...")
        exit()

    algo : str = algType()
    kSize : int = kernSize()
    p : int = param()
    fNameIn : str = inFileName()
    fNameOut : str = outFileName()

# load image with PIL 

def loadImg():
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





def main():
    processArgs()
    arr = loadImg()

    # print(arr)


if __name__ == "__main__":
    main()
