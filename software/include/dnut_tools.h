/*
 * Copyright 2016 International Business Machines
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

#ifndef __DNUT_TOOLS_H__
#define __DNUT_TOOLS_H__

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <termios.h>
#include <getopt.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <time.h>		/* clock_gettime and friends */
#include <sys/types.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <sysexits.h>		/* standart application exit codes */

#define DNUT_TOOL_VERS_STRING	"3.0.25"

/*****************************************************************************/
/** Useful macros in case they are not defined somewhere else		     */
/*****************************************************************************/

#ifndef ARRAY_SIZE
#  define ARRAY_SIZE(a)  (sizeof((a)) / sizeof((a)[0]))
#endif

#ifndef ABS
#  define ABS(a)	 (((a) < 0) ? -(a) : (a))
#endif

#ifndef MAX
#  define MAX(a,b)	({ __typeof__ (a) _a = (a); \
			   __typeof__ (b) _b = (b); \
			_a > _b ? _a : _b; })
#endif

#ifndef MIN
#  define MIN(a,b)	({ __typeof__ (a) _a = (a); \
			   __typeof__ (b) _b = (b); \
			_a < _b ? _a : _b; })
#endif

/**
 * Common tool return codes
 *       0: EX_OK/EXIT_SUCCESS
 *       1: Catchall for general errors/EXIT_FAILURE
 *       2: Misuse of shell builtins (according to Bash documentation)
 *  64..78: predefined in sysexits.h
 *
 * 79..128: Exit codes for our applications
 *
 *     126: Command invoked cannot execute
 *     127: "command not found"
 *     128: Invalid argument to exit
 *   128+n: Fatal error signal "n"
 *     255: Exit status out of range (exit takes only integer args in the
 *          range 0 - 255)
 */
#define EX_ERRNO	79 /* libc problem */
#define EX_MEMORY	80 /* mem alloc failed */
#define EX_ERR_DATA	81 /* data not as expected */
#define EX_ERR_CRC	82 /* CRC wrong */
#define EX_ERR_ADLER	83 /* Adler checksum wrong */
#define EX_ERR_CARD	84 /* accelerator problem */
#define EX_COMPRESS	85 /* compression did not work */
#define EX_DECOMPRESS	86 /* decompression failed */
#define EX_ERR_DICT     87 /* dictionary compare failed */

/** common error printf */
#define pr_err(fmt, ...) do {					\
		fprintf(stderr, "%s:%u: Error: " fmt,		\
		       __FILE__, __LINE__, ## __VA_ARGS__);	\
	} while (0)

/** _dbg_flag must be defined elsewhere */
extern int _dbg_flag;

#define	pr_dbg(fmt, ...) do {					\
		if (_dbg_flag)					\
			fprintf(stdout, fmt, ## __VA_ARGS__);	\
	} while(0)

/** verbose_flag must be defined elsewhere */
extern int verbose_flag;

#define pr_info(fmt, ...) do {					\
		if (verbose_flag)				\
			fprintf(stdout, fmt, ## __VA_ARGS__);	\
	} while (0)

/* FIXME Fake this for old RHEL verions e.g. RHEL5.6 */
#ifndef CLOCK_MONOTONIC_RAW
#define   clock_gettime(clk_id, tp) ({ int val = 0; val; })
#endif

#endif		/* __DNUT_TOOLS_H__ */
