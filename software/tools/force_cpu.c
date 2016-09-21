/*
 * Copyright 2016, International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <signal.h>
#include <sys/time.h>

#include <sched.h>
#include <utmpx.h>
#include "force_cpu.h"

/* FIXME Fake this for old RHEL verions e.g. RHEL5.6 */
#ifndef CPU_ALLOC
#define	  CPU_ALLOC(cpus)		      ({ void *ptr = NULL; ptr; })
#define	  CPU_ALLOC_SIZE(cpus)		      ({ int val = 0; val; })
#define	  CPU_ISSET_S(cpu, size, cpusetp)     ({ int val = 0; val; })
#define	  CPU_FREE(cpusetp)
#define	  CPU_ZERO_S(size, cpusetp)
#define	  CPU_SET_S(run_cpu, size, cpusetp)
#define	  sched_getcpu()		      ({ int val = 0; val; })
#define	  sched_setaffinity(x, size, cpusetp) ({ int val = 0; val; })
#endif

void print_cpu_mask(void)
{
	cpu_set_t *cpusetp;
	size_t size;
	int num_cpus, cpu;

	num_cpus = CPU_SETSIZE; /* take default, currently 1024 */
	cpusetp = CPU_ALLOC(num_cpus);
	if (cpusetp == NULL)
		return;
	size = CPU_ALLOC_SIZE(num_cpus);

	/* figure out on which cpus we might run now after change */
	CPU_ZERO_S(size, cpusetp);
	if (sched_getaffinity(0, size, cpusetp) < 0) {
		CPU_FREE(cpusetp);
		return;
	}
	for (cpu = 0; cpu < num_cpus; cpu += 1) {
		if (!CPU_ISSET_S(cpu, size, cpusetp)) {
			printf("\n");
			break;
		}
		printf(" CPU: %4d = %s", cpu,
		       CPU_ISSET_S(cpu, size, cpusetp)?"yes":"no ");

		if ((cpu & 0x3) == 0x3)
			printf("\n");

	}
	CPU_FREE(cpusetp);
}

/**
 * Try to ping process to a specific CPU. Returns the CPU we are
 * currently running on.
 */
int pin_to_cpu(int run_cpu)
{
	cpu_set_t *cpusetp;
	size_t size;
	int num_cpus;

	num_cpus = CPU_SETSIZE; /* take default, currently 1024 */
	cpusetp = CPU_ALLOC(num_cpus);
	if (cpusetp == NULL) {
		return sched_getcpu();
	}
	size = CPU_ALLOC_SIZE(num_cpus);

	CPU_ZERO_S(size, cpusetp);
	CPU_SET_S(run_cpu, size, cpusetp);
	if (sched_setaffinity(0, size, cpusetp) < 0) {
		CPU_FREE(cpusetp);
		return sched_getcpu();
	}

	/* figure out on which cpus we actually run */
	CPU_FREE(cpusetp);
	return run_cpu;
}

int switch_cpu(int cpu, int verbose)
{
	int new_cpu;

	/* pin to specific CPU to get more precise performance measurements */
	if (cpu < 0)
		return 0;

	if (verbose) {
		printf("Default possible CPUs:\n");
		print_cpu_mask();
		printf("Running on CPU %d, want to run on CPU %d...\n",
		       sched_getcpu(), cpu);
	}
	new_cpu = pin_to_cpu(cpu);
	if (new_cpu != cpu) {
		fprintf(stderr, "err: desired CPU %d does not match current "
			"CPU %d\n", cpu, new_cpu);
		return -1;
	}
	if (verbose) {
		printf("New possible CPUs:\n");
		print_cpu_mask();
		printf("Running on CPU %d\n", new_cpu);
	}
	return 0;
}
