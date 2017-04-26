//
// C program for Rabin Karp Pattern Searching algorithm
//
// Origin:
//   http://www.geeksforgeeks.org/searching-for-patterns-set-3-rabin-karp-algorithm/
//
// License:
//   https://creativecommons.org/licenses/by-nc-nd/2.5/in/deed.en_US
//
#include<stdio.h>
#include<string.h>
#include "action_search.H"

//  is the number of characters in input alphabet
//#define d 256 ==> replaced by NO_OF_CHARS
 
/* pat -> pattern
    txt -> text
    q -> A prime number
*/
int RKsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N, int q)
{
    //int M = strlen(pat);
    //int N = strlen(txt);
    int i, j;
    int p = 0; // hash value for pattern
    int t = 0; // hash value for txt
    int h = 1;
    int count = 0;
 
    // The value of h would be "pow(NO_OF_CHARS, M-1)%q"
    for (i = 0; i < M-1; i++)
           h = (h*NO_OF_CHARS)%q;
 
    // Calculate the hash value of pattern and first
    // window of text
    for (i = 0; i < M; i++)
    {
        p = (NO_OF_CHARS*p + pat[i])%q;
        t = (NO_OF_CHARS*t + txt[i])%q;
    }
 
    // Slide the pattern over text one by one
    for (i = 0; i <= N - M; i++)
      {
 
        // Check the hash values of current window of text
        // and pattern. If the hash values match then only
        // check for characters on by one
        if ( p == t )
        {
            /* Check for characters one by one */
            for (j = 0; j < M; j++)
            {
                if (txt[i+j] != pat[j])
                    break;
            }
 
            // if p == t and pat[0...M-1] = txt[i, i+1, ...i+M-1]
            if (j == M)
            {
                printf("Pattern found at index %d \n", i);
                count++;
            }
        }
 
        // Calculate hash value for next window of text: Remove
        // leading digit, add trailing digit
        if ( i < N-M )
        {
            t = (NO_OF_CHARS*(t - txt[i]*h) + txt[i+M])%q;
 
            // We might get negative value of t, converting it
            // to positive
            if (t < 0)
            t = (t + q);
        }
      }
    return count;
}
 
#ifdef NO_SYNTH
// Synthesis clock = 3.5 - 2393 LUts - latency : 36+39+3
/* Driver program to test above function */
int main(void)
{
	char txt[] = "The dog was afraid of the cat. But was it really a dog or a cat?";
	char pat[] = "dog";
	//char txt[] = "GEEKS FOR GEEKS";
    //char pat[] = "GEEK";
    int q = 101; // A prime number

    int rc;

    rc = RKsearch(pat, strlen(pat), txt, strlen(txt), q);
    // BM : line added to return a value
    printf("Number of Pattern founds: %d \n", rc);
    return 0;
}
#endif
