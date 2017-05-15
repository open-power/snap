/*
 * Copyright 2016 , 2017 International Business Machines
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

#ifndef __FORCE_CPU_H__
#define __FORCE_CPU_H__

#include <stdint.h>

void print_cpu_mask(void);
int  pin_to_cpu(int run_cpu);
int  switch_cpu(int cpu, int verbose);

#endif	/* __FORCE_CPU_H__ */
