//
// C program for Finite Automata Pattern Searching algorithm
//
// Origin:
//   http://www.geeksforgeeks.org/searching-for-patterns-set-5-finite-automata/
//
// License:
//   https://creativecommons.org/licenses/by-nc-nd/2.5/in/deed.en_US
//
#include<stdio.h>
#include<string.h>
#include "action_search.H"

int getNextState(char pat[PATTERN_SIZE], int M, int state, int x)
{
  // If the character c is same as next character in pattern,
  // then simply increment state
  if (state < M && x == pat[state])
  return state+1;
 
  int ns, i; // ns stores the result which is next state
 
  // ns finally contains the longest prefix which is also suffix
  // in "pat[0..state-1]c"
 
  // Start from the largest possible value and stop when you find
  // a prefix which is also suffix
  for (ns = state; ns > 0; ns--)
		  if(pat[ns-1] == x)
		  {
			  for(i = 0; i < ns-1; i++)
			  {
				  if (pat[i] != pat[state-ns+1+i])
					  break;
			  }
			  if (i == ns-1)
				  return ns;
		  }
  return 0;
}
 
/* This function builds the TF table which represents Finite Automata for a
  given pattern */
void computeTF(char pat[PATTERN_SIZE], int M, int TF[PATTERN_SIZE+1][NO_OF_CHARS])
{
  int state, x;
  for (state = 0; state <= M; ++state)
    	  for (x = 0; x < NO_OF_CHARS; ++x)
		  	  TF[state][x] = getNextState(pat, M, state, x);
}
 
/* Prints all occurrences of pat in txt */
int FAsearch(char pat[PATTERN_SIZE], int M, char txt[TEXT_SIZE], int N)
{
//  int M = strlen(pat);
//  int N = strlen(txt);

  int TF[PATTERN_SIZE+1][NO_OF_CHARS];
  int count = 0;
 
  computeTF(pat, M, TF);
 
  // Process txt over FA.
  int i, state=0;
  for (i = 0; i < N; i++)
  {
	  state = TF[state][txt[i]];
  	  if (state == M)
  	  {
		  printf ("Pattern found at index %d\n", i-M+1);
		  count++;
  	  }
   }
  return count;
}
 
#ifdef NO_SYNTH
//Synthesis clock 3.46 - 697 LUTs - latency 5?
// Driver program to test above function
int main(void)
{
	char txt[] = "The dog was afraid of the cat. But was it really a dog or a cat?";
	char pat[] = "dog";
//	char *txt = "A ABAACAAD A ABAAABAA";
//  char *pat = "A ABA";
  int rc;

  rc = FAsearch(pat, strlen(pat), txt, strlen(txt));
  // BM : line added to return a value
  printf("Number of Pattern founds: %d \n", rc);
  return 0;
}
#endif
