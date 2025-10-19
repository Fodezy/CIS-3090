#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdbool.h>

static double computePi(long long iterations) {
    // pi = 4 * ∑{k=0..n-1} (-1)^k / (2k+1)
    double sum = 0.0;
    double sign = 1.0;
    for (long long k = 0; k < iterations; ++k) {
        double denom = (double)(2 * k + 1);
        sum += sign / denom;
        sign = -sign;
    }
    return 4.0 * sum;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <iterations>\n", argv[0]);
        return EXIT_FAILURE;
    }

    char *end = NULL;
    errno = 0;
    long long iters = strtoll(argv[1], &end, 10);
    if (errno != 0 || end == argv[1] || *end != '\0' || iters <= 0) {
        fprintf(stderr, "Invalid iterations: %s (must be positive integer)\n", argv[1]);
        return EXIT_FAILURE;
    }

    double pi = computePi(iters);
    printf("Computed Pi using %lld iterations, the result is %.12f\n", iters, pi);
    return EXIT_SUCCESS;
}
