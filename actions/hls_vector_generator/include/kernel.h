#ifndef __GPU_KERNEL_H__
#define __GPU_KERNEL_H__

#ifdef __cplusplus
extern "C" {
#endif

void cuda_add(void* A, void* B, void* C, int N);
void cuda_Finish();

#ifdef __cplusplus
}
#endif
#endif
