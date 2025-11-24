import warp as wp
import numpy as np

wp.init()

num_points = 12
device = "cpu"

@wp.kernel
def length(x: wp.array(dtype=float),
           y: wp.array(dtype=float),
           z: wp.array(dtype=float)):

    # thread index
    tid = wp.tid()

    # compute the sum
    z[tid] = x[tid]+y[tid]


# allocate arrays of points
# hostX = np.random.rand(num_points, 1).flatten()
# hostY = np.random.rand(num_points, 1).flatten()
hostX = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], dtype=float)
hostY = np.array([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], dtype=float)

# This is our usual sanity check - we perform a serial calculation
hostZ = np.add(hostX, hostY)

x = wp.array(hostX, dtype=float, device=device)
y = wp.array(hostY, dtype=float, device=device)
z = wp.zeros(num_points, dtype=float, device=device)

print(len(z))
print(hostX.shape)
print(hostY.shape)
print(hostZ.shape)

# launch kernel
wp.launch(kernel=length,
          dim=len(z),
          inputs=[x, y, z],
          device=device)

print(z.numpy())
print(hostZ)