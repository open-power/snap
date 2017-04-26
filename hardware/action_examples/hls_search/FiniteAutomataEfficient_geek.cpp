//
// C program for Efficient Construction of Finite Automata  Pattern Searching algorithm
//
// Origin:
//   http://www.geeksforgeeks.org/pattern-searching-set-5-efficient-constructtion-of-finite-automata/
//
// License:
//   https://creativecommons.org/licenses/by-nc-nd/2.5/in/deed.en_US
//
#include<stdio.h>
#include<string.h>
#include "action_search.H"

/* This function builds the TF table which represents Finite Automata for a
   given pattern  */
void computeTransFun(char pat[PATTERN_SIZE], int M, int TF[PATTERN_SIZE][NO_OF_CHARS])
{
    int i, lps = 0, x;
 
    // Fill entries in first row
    for (x =0; x < NO_OF_CHARS; x++)
       TF[0][x] = 0;
    TF[0][pat[0]] = 1;
 
    // Fill entries in other rows
    for (i = 1; i<= M; i++)
    {
        // Copy values from row at index lps
        for (x = 0; x < NO_OF_CHARS; x++)
            TF[i][x] = TF[lps][x];
 
        // Update the entry corresponding to this character
        TF[i][pat[i]] = i + 1;
 
        // Update lps for next row to be filled
        if (i < M)
          lps = TF[lps][pat[i]];
    }
}
 
/* Prints all occurrences of pat in txt */
int FAEsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N)
{
    //int M = strlen(pat);
    //int N = strlen(txt);
	int count = 0;
 
    //int TF[PATTERN_SIZE+1][NO_OF_CHARS];
    int TF[PATTERN_SIZE+1][NO_OF_CHARS];
 
    computeTransFun(pat, M, TF);
 
    // process text over FA.
    int i, j=0;
    for (i = 0; i < N; i++)
    {
       j = TF[j][txt[i]];
       if (j == M)
       {
         printf (" pattern found at index %d\n", i-M+1);
         count++;
       }
    }
    return count;
}
 
#ifdef NO_SYNTH
/* Driver program to test above function */
int main(void)
{
	char txt[] = "The dog was afraid of the cat. But was it really a dog or a cat?";
	char pat[] = "dog";
	//char *txt = "GEEKS FOR GEEKS";
    //char *pat = "GEEKS";
    int rc;

    rc = FAEsearch(pat, strlen(pat), txt, strlen(txt));
    // BM : line added to return a value
    printf("Number of Pattern founds: %d \n", rc);
    //getchar();
    return 0;
}
#endif
