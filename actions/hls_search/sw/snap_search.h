#ifndef __SNAP_SEARCH_H__
#define __SNAP_SEARCH_H__

/*
 * Copyright 2016, 2017 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <libsnap.h>
#include <action_search.h>

unsigned int run_sw_search(unsigned int Method, char *Pattern,
           unsigned int PatternSize, char *Text, unsigned int TextSize);
int Naive_search(char *pat, int M, char *txt, int N);
void preprocess_KMP_table(char *pat, int M, int KMP_table[]);
int KMP_search(char *pat, int M, char *txt, int N);

#endif	/* __ACTION_SEARCH_H__ */
