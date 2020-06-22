#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <mma.h>

using namespace nvcuda;


__global__ void warpGemm(half *A, half *B, float *C) {
  wmma::fragment<wmma::matrix_a, 16, 16, 16, half, wmma::row_major> a_frag;
  wmma::fragment<wmma::matrix_b, 16, 16, 16, half, wmma::row_major> b_frag;
  wmma::fragment<wmma::accumulator, 16, 16, 16, float> c_frag;

  wmma::load_matrix_sync(a_frag, A, 16);
  wmma::load_matrix_sync(b_frag, B, 16);
  wmma::fill_fragment(c_frag, 0.0f);

  wmma::mma_sync(c_frag, a_frag, b_frag, c_frag);

  wmma::store_matrix_sync(C, c_frag, 16, wmma::mem_row_major);
}

__global__ void float2half_mat(float *a, float *b, int n, half *ha, half *hb) {
  int i = threadIdx.x + blockIdx.x * blockDim.x;

  if (i < n) {
    ha[i] = __float2half(a[i]);
    hb[i] = __float2half(b[i]);
  }
}

int main() {
    const size_t N2 = 16*16;
    const size_t matSize = sizeof(float) * N2;

    // Generate inputs
    float input_A = [
            7.0,7.0,6.0,1.0,8.0,6.0,6.0,9.0,9.0,6.0,4.0,5.0,5.0,0.0,2.0,6.0
            5.0,6.0,7.0,0.0,8.0,6.0,3.0,0.0,8.0,0.0,3.0,9.0,0.0,7.0,9.0,2.0
            5.0,2.0,3.0,0.0,3.0,5.0,5.0,0.0,2.0,7.0,6.0,3.0,7.0,8.0,4.0,4.0
            7.0,8.0,3.0,3.0,0.0,5.0,2.0,0.0,8.0,7.0,7.0,1.0,6.0,5.0,8.0,3.0
            5.0,7.0,3.0,2.0,0.0,7.0,8.0,7.0,3.0,5.0,3.0,0.0,0.0,3.0,5.0,2.0
            1.0,6.0,0.0,3.0,5.0,6.0,9.0,7.0,7.0,8.0,2.0,1.0,7.0,0.0,6.0,1.0
            2.0,6.0,2.0,4.0,1.0,4.0,8.0,7.0,1.0,8.0,6.0,9.0,2.0,9.0,9.0,9.0
            8.0,7.0,9.0,0.0,7.0,0.0,9.0,9.0,3.0,6.0,8.0,8.0,8.0,5.0,4.0,0.0
            8.0,4.0,5.0,1.0,8.0,0.0,0.0,0.0,4.0,1.0,1.0,7.0,2.0,7.0,9.0,3.0
            5.0,8.0,7.0,2.0,2.0,6.0,8.0,8.0,0.0,1.0,1.0,2.0,6.0,8.0,6.0,7.0
            6.0,8.0,8.0,8.0,1.0,9.0,9.0,1.0,5.0,3.0,3.0,2.0,8.0,0.0,2.0,1.0
            6.0,2.0,6.0,9.0,2.0,0.0,4.0,7.0,1.0,2.0,5.0,7.0,7.0,9.0,8.0,2.0
            3.0,7.0,7.0,4.0,7.0,4.0,6.0,4.0,4.0,2.0,9.0,1.0,6.0,1.0,1.0,6.0
            8.0,8.0,7.0,1.0,5.0,6.0,2.0,3.0,8.0,1.0,2.0,3.0,1.0,9.0,9.0,9.0
            6.0,2.0,7.0,8.0,4.0,0.0,9.0,3.0,6.0,7.0,0.0,6.0,1.0,8.0,2.0,2.0
            1.0,5.0,4.0,6.0,2.0,4.0,6.0,8.0,2.0,3.0,7.0,3.0,3.0,7.0,6.0,8.0

    ];

    float input_B = [
            0.0,5.0,7.0,6.0,9.0,8.0,3.0,3.0,8.0,9.0,3.0,9.0,6.0,8.0,1.0,4.0
            7.0,8.0,3.0,5.0,2.0,6.0,5.0,9.0,4.0,1.0,4.0,8.0,1.0,8.0,5.0,9.0
            9.0,5.0,7.0,9.0,5.0,1.0,0.0,1.0,5.0,0.0,3.0,2.0,2.0,3.0,5.0,8.0
            9.0,3.0,6.0,1.0,9.0,9.0,1.0,6.0,3.0,5.0,9.0,2.0,8.0,5.0,6.0,4.0
            7.0,6.0,7.0,2.0,9.0,8.0,4.0,6.0,2.0,3.0,1.0,3.0,9.0,7.0,5.0,9.0
            8.0,6.0,1.0,4.0,5.0,2.0,8.0,0.0,8.0,8.0,6.0,8.0,9.0,0.0,3.0,6.0
            9.0,6.0,3.0,9.0,7.0,3.0,9.0,5.0,0.0,5.0,2.0,2.0,9.0,3.0,1.0,3.0
            6.0,9.0,8.0,6.0,2.0,7.0,9.0,0.0,8.0,0.0,5.0,2.0,5.0,1.0,6.0,3.0
            6.0,0.0,3.0,4.0,0.0,5.0,1.0,3.0,1.0,2.0,1.0,0.0,2.0,0.0,3.0,2.0
            9.0,7.0,3.0,1.0,7.0,1.0,7.0,0.0,5.0,0.0,7.0,9.0,3.0,7.0,3.0,7.0
            6.0,5.0,0.0,4.0,7.0,8.0,9.0,1.0,0.0,9.0,9.0,2.0,5.0,6.0,5.0,9.0
            0.0,9.0,7.0,7.0,3.0,5.0,5.0,8.0,2.0,2.0,6.0,3.0,6.0,4.0,8.0,3.0
            4.0,5.0,4.0,3.0,0.0,3.0,4.0,0.0,7.0,5.0,7.0,3.0,9.0,8.0,0.0,9.0
            0.0,9.0,9.0,2.0,2.0,9.0,9.0,6.0,6.0,0.0,9.0,4.0,2.0,3.0,9.0,5.0
            3.0,5.0,8.0,9.0,0.0,5.0,4.0,0.0,7.0,6.0,7.0,8.0,3.0,0.0,9.0,7.0
            5.0,5.0,4.0,2.0,6.0,9.0,1.0,2.0,3.0,2.0,8.0,5.0,2.0,1.0,7.0,8.0
    ];

    float *output_C = (float *) malloc(matSize);
    for (int i = 0; i < N2; i++)
        output_C[i] = 0;

    // malloc for cuda
    float *cuda_A = nullptr;
    cudaMalloc(&cuda_A, matSize);

    float *cuda_B = nullptr;
    cudaMalloc(&cuda_B, matSize);

    half *A = nullptr;
    cudaMalloc(&A, matSize/2);

    half *B = nullptr;
    cudaMalloc(&B, matSize/2);

    float *cuda_C = nullptr
    cudaMalloc(&cuda_C, matSize);

    // copy to cuda
    cudaMemcpy(cuda_A, input_A, matSize, cudaMemcpyHostToDevice);
    cudaMemcpy(cuda_B, input_B, matSize, cudaMemcpyHostToDevice);

    float2half_mat<<<1, 16*16>>>(cuda_A, cuda_B, N2, A, B);

    warpGemm<<<1, 32>>>(A, B, cuda_C);

    cudaMemcpy(output_C, cuda_C, matSize, cudaMemcpyDeviceToHost);

    for(int i = 0; i < 16; i++)
        for (int j =0; j < 16; j++)
            printf("%f", output_C[i*16+j]);

    return 0;
}
