//
//  C Program for Bad Character Heuristic of Boyer Moore String Matching Algorithm 
//
// Origin:
//   http://www.geeksforgeeks.org/pattern-searching-set-7-boyer-moore-algorithm-bad-character-heuristic/
//
// License:
//   https://creativecommons.org/licenses/by-nc-nd/2.5/in/deed.en_US
//
 
# include <limits.h>
# include <string.h>
# include <stdio.h>
#include "action_search.H"
 
// A utility function to get maximum of two integers
int max (int a, int b) { return (a > b)? a: b; }
 
// The preprocessing function for Boyer Moore's bad character heuristic
void badCharHeuristic( char str[PATTERN_SIZE], int size, int badchar[NO_OF_CHARS])
{
    int i;
 
    // Initialize all occurrences as -1
    for (i = 0; i < NO_OF_CHARS; i++)
#pragma HLS UNROLL
         badchar[i] = -1;
 
    // Fill the actual value of last occurrence of a character
    //for (i = 0; i < size; i++)
    for (i = 0; i < PATTERN_SIZE; i++)
#pragma HLS UNROLL
         if(i < size)
             badchar[(int) str[i]] = i;
}
 
/* A pattern searching function that uses Bad Character Heuristic of
   Boyer Moore Algorithm */
int BMsearch(char pat[PATTERN_SIZE], int m, char txt[TEXT_SIZE], int n)
{
#pragma HLS INLINE off
//    int m = strlen(pat);
//    int n = strlen(txt);
    int count = 0;
 
    int badchar[NO_OF_CHARS];
 
    /* Fill the bad character array by calling the preprocessing
       function badCharHeuristic() for given pattern */
    badCharHeuristic(pat, m, badchar);
 
    int s = 0;  // s is shift of the pattern with respect to text
    while(s <= (n - m))
    {
        int j = m-1;
 
        /* Keep reducing index j of pattern while characters of
           pattern and text are matching at this shift s */
        while(j >= 0 && pat[j] == txt[s+j])
            j--;
 
        /* If the pattern is present at current shift, then index j
           will become -1 after the above loop */
        if (j < 0)
        {
            printf("pattern occurs at shift = %d\n", s);
            count++;
 
            /* Shift the pattern so that the next character in text
               aligns with the last occurrence of it in pattern.
               The condition s+m < n is necessary for the case when
               pattern occurs at the end of text */
            s += (s+m < n)? m-badchar[txt[s+m]] : 1;
 
        }
 
        else
            /* Shift the pattern so that the bad character in text
               aligns with the last occurrence of it in pattern. The
               max function is used to make sure that we get a positive
               shift. We may get a negative shift if the last occurrence
               of bad character in pattern is on the right side of the
               current character. */
            s += max(1, j - badchar[txt[s+j]]);
    }
    return count;
}
 
#ifdef NO_SYNTH
// Synthesis clock 3.30 - 711 LUTs - latency 8?
/* Driver program to test above funtion */
int main(void)
{
	char txt[] = "The dog was afraid of the cat. But was it really a dog or a cat?";
	char pat[] = "dog";
	//char txt[] = "ABAAABCD A BC";
    //char pat[] = "A BC";
    int rc;

    rc = BMsearch(txt, strlen(txt), pat, strlen(pat));
    // BM : line added to return a value
    printf("Number of Pattern founds: %d \n", rc);
    return 0;
}
#endif
