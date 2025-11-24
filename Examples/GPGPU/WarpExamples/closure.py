import warp as wp

def create_kernel(N):
    @wp.kernel
    def k():
        v = wp.vector(dtype=float, length=N)
        for x in range(N):
            v[x] = float(x) + 1.0
        print(v)

    return k

wp.init()

k3 = create_kernel(3)
k5 = create_kernel(5)

wp.launch(k3, dim=4)
wp.launch(k5, dim=4)

wp.synchronize_device()