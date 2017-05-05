//
// C++ program for Knuth Morris Pratt Pattern Searching algorithm
//
// Origin:
//   http://www.geeksforgeeks.org/searching-for-patterns-set-2-kmp-algorithm/
//
// License:
//   https://creativecommons.org/licenses/by-nc-nd/2.5/in/deed.en_US
//
#include<bits/stdc++.h>
#include "action_search.H"
 
// Fills lps[] for given patttern pat[0..M-1]
//void computeLPSArray(char *pat, int M, int *lps)
void computeLPSArray(char pat[PATTERN_SIZE], int M, int *lps)
{
#pragma HLS INLINE off
    // length of the previous longest prefix suffix
    int len = 0;

    lps[0] = 0; // lps[0] is always 0

    // the loop calculates lps[i] for i = 1 to M-1
    int i = 1;
    while (i < M)
    {
        if (pat[i] == pat[len])
        {
            len++;
            lps[i] = len;
            i++;
        }
        else // (pat[i] != pat[len])
        {
            // This is tricky. Consider the example.
            // AAACAAAA and i = 7. The idea is similar
            // to search step.
            if (len != 0)
            {
                len = lps[len-1];

                // Also, note that we do not increment
                // i here
            }
            else // if (len == 0)
            {
                lps[i] = 0;
                i++;
            }
        }
    }
}


// Prints occurrences of txt[] in pat[]
//void KMPsearch(char *pat, char *txt)
int KMPsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N)
{
#pragma HLS INLINE off
	// Moved to main()
    //int M = strlen(pat);
    //int N = strlen(txt);
 
    // create lps[] that will hold the longest prefix suffix
    // values for pattern
    //int lps[M];
    int lps[PATTERN_SIZE];
 
    // Preprocess the pattern (calculate lps[] array)
    computeLPSArray(pat, M, lps);
 
    int i = 0;  // index for txt[]
    int j  = 0;  // index for pat[]
    int count = 0;

    while (i < N)
    {
        if (pat[j] == txt[i])
        {
            j++;
            i++;
        }
 
        if (j == M)
        {
            printf("Found pattern at index %d \n", i-j);
            j = lps[j-1];
            count++;
        }
 
        // mismatch after j matches
        else if (i < N && pat[j] != txt[i])
        {
            // Do not match lps[0..lps[j-1]] characters,
            // they will match anyway
            if (j != 0)
                j = lps[j-1];
            else
                i = i+1;
        }
    }
    return count;
}

#ifdef NO_SYNTH
// Synthesis : clk = 4.78 !! - 901LUTs - latency 4-5 + 6
// Driver program to test above function
int main(void)
{
	char txt[] = "The dog was afraid of the cat. But was it really a dog or a cat?";
	char pat[] = "dog";
	//char *txt = "ABABDABACD ABABCABAB";
    //char *pat = "ABABCABAB";
    int rc;

    //moved from KMPSearch function since strlen not supported by HLS
    //KMPSearch(pat, txt);
    rc = KMPsearch(pat, strlen(pat), txt, strlen(txt));
    // BM : line added to return a value
    printf("Number of Pattern founds: %d \n", rc);
    return 0;
}
#endif
