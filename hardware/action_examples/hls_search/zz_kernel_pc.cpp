/* Following program is a C implementation of Rabin Karp
Algorithm given in the CLRS book */
#include<stdio.h>
#include<string.h>
 
// d is the number of characters in input alphabet
#define d 256
#define PATTERN_SIZE 15
#define TEXT_SIZE 150
 
    int Nsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
    int KMPSearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
    int FAsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
    int FAEsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
    int BMsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N);
 
#ifdef NO_SYNTH
// Synthesis clock = 3.5 - 2393 LUts - latency : 36+39+3
/* Driver program to test above function */
int main()
{
	char txt[] = "The dog was afraid of the cat. But was it really a dog or a cat?";
	char pat[] = "dog";
    int q = 101; // A prime number

    if(Nsearch(pat, strlen(pat), txt, strlen(txt)) == 2) printf("Naive search OK\n");
    if(KMPSearch(pat, strlen(pat), txt, strlen(txt)) == 2) printf("KMP search OK\n");
    if(FAsearch(pat, strlen(pat), txt, strlen(txt)) == 2) printf("FA search OK\n");
    if(FAEsearch(pat, strlen(pat), txt, strlen(txt)) == 2) printf("FAE search OK\n");
    if(BMsearch(txt, strlen(txt), pat, strlen(pat)) == 2) printf("BM search OK\n");

    return 0;
}
#endif
