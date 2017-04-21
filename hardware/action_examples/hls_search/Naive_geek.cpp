//
// C program for Naive Pattern Searching algorithm
//
// Origin:
//   http://www.geeksforgeeks.org/searching-for-patterns-set-1-naive-pattern-searching
//
// License:
//   https://creativecommons.org/licenses/by-nc-nd/2.5/in/deed.en_US
//

#include <stdio.h>
#include <string.h>

#include "action_search.H"

/* void search(char *pat, char *txt) */
/* int Nsearch(char *pat, int M, char *txt, int N) */

int Nsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N)
{
#pragma HLS INLINE off
//  int M = strlen(pat);
//  int N = strlen(txt);
    int count=0;

    /* A loop to slide pat[] one by one */
    for (int i = 0; i <= N - M; i++)
    {
        int j;
  
        /* For current index i, check for pattern match */
        for (j = 0; j < M; j++)
            if (txt[i+j] != pat[j])
                break;
 
        if (j == M)  // if pat[0...M-1] = txt[i, i+1, ...i+M-1]
        {
           count++; // BM : line added to return a value
           printf("Pattern found at index %d \n", i);
        }
    }
    return count;
}

#ifdef NO_SYNTH  
// Synthesis clock = 3.26 - 300LUTs - Latency 3?
/* Driver program to test above function */
int main(void)
{
   char txt[] = "The dog was afraid of the cat. But was it really a dog or a cat?";
   char pat[] = "dog";
   int rc;

   //moved from search function since strlen not supported by HLS
   //search(pat, txt);
   rc = Nsearch(pat, strlen(pat), txt, strlen(txt));
   // BM : line added to return a value
   printf("Number of Pattern founds: %d \n", rc);
   return 0;
}
#endif
