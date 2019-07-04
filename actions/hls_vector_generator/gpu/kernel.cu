#include <kernel.h>
#include <stdint.h>

uint8_t *d_A, *d_B, *d_C;

__global__ void add_uint8(uint8_t *A, uint8_t *B, uint8_t *C, int N){

	int id = blockIdx.x*blockDim.x+threadIdx.x;
	if (id<N){
		C[id] = A[id] + B[id];
	}
}


void cuda_add(void* A, void* B, void* C, int N){

	size_t size = N*sizeof(uint8_t);

	cudaMalloc(&d_A, size);
	cudaMalloc(&d_B, size);
	cudaMalloc(&d_C, size);

	cudaMemcpy(d_A, A, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_B, B, size, cudaMemcpyHostToDevice);

	int blockSize = 64;
	int numBlocks = N/64;

	add_uint8<<<numBlocks,blockSize>>>(d_A,d_B,d_C,N);

	cudaMemcpy(C,d_C, size, cudaMemcpyDeviceToHost);
	
}

void cuda_Finish(){
	
	cudaFree(d_A);
	cudaFree(d_B);
	cudaFree(d_C);
}
