#include <stdio.h>

#define NUM_THREADS 1000000
#define ARRAY_SIZE  16 

#define BLOCK_WIDTH 1000 

void print_array(int *array, int size)
{
    printf("{ ");
    for (int i = 0; i < size; i++)  { printf("%d ", array[i]); }
    printf("}\n");
}

__global__ void increment_naive(int *g)
{
    // which thread is this?
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    // each thread to increment consecutive elements, wrapping at ARRAY_SIZE
    i = i % ARRAY_SIZE;
    g[i] = g[i] + 1;
}

__global__ void increment_atomic(int *g)
{
    // which thread is this?
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    // each thread to increment consecutive elements, wrapping at ARRAY_SIZE
    i = i % ARRAY_SIZE;
    atomicAdd(&g[i], 1);

}

int main(int argc,char **argv)
{
    // Informative printout
    printf("%d total threads in %d blocks writing into %d array elements\n",
           NUM_THREADS, NUM_THREADS / BLOCK_WIDTH, ARRAY_SIZE);

    // declare and allocate host memory
    int h_array[ARRAY_SIZE];
    const int ARRAY_BYTES = ARRAY_SIZE * sizeof(int);

    // declare, allocate, and zero out GPU memory
    int * d_array;
    cudaMalloc((void **) &d_array, ARRAY_BYTES);

    // Fill the device memory area with zeros  .
    cudaMemset((void *) d_array, 0, ARRAY_BYTES);

    // Call kernel with atomic operation
    increment_atomic<<<NUM_THREADS/BLOCK_WIDTH, BLOCK_WIDTH>>>(d_array);

    // Call kernel without atomic operation
//    increment_naive<<<NUM_THREADS/BLOCK_WIDTH, BLOCK_WIDTH>>>(d_array);

    // copy back the array of sums from GPU and print
    cudaMemcpy(h_array, d_array, ARRAY_BYTES, cudaMemcpyDeviceToHost);
    print_array(h_array, ARRAY_SIZE);

    // free GPU memory allocation and exit
    cudaFree(d_array);
    return 0;
}
