import sys
import numpy as np
from PIL import Image

image = Image.open(sys.argv[1])

# summarize some details about the image
print(image.format)
print(image.size)
print(image.mode)

#convert the image into a NumPy array
numpyArr = np.asarray(image, dtype='float32')
print(numpyArr.shape)

#create new image from the numpu array
image2 = Image.fromarray(np.uint8(numpyArr))
print(type(image2))

# summarize image details
print(image2.mode)
print(image2.size)

#save new image to the disk
#it should be identical to the image passes as command line arg
image2.save('out.png')