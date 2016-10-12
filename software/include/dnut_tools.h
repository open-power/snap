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
#include <limits.h>
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

/**
 * str_to_num - Convert string into number and cope with endings like
 *              KiB for kilobyte
 *              MiB for megabyte
 *              GiB for gigabyte
 */
static inline uint64_t __str_to_num(char *str)
{
	char *s = str;
	uint64_t num = strtoull(s, &s, 0);

	if (*s == '\0')
		return num;

	if (strcmp(s, "KiB") == 0)
		num *= 1024;
	else if (strcmp(s, "MiB") == 0)
		num *= 1024 * 1024;
	else if (strcmp(s, "GiB") == 0)
		num *= 1024 * 1024 * 1024;
	else {
		pr_err("--size or -s out of range, use KiB/MiB or GiB only\n");
		num = ULLONG_MAX;
		errno = ERANGE;
		exit(EXIT_FAILURE);
	}
	return num;
}

static inline void __hexdump(FILE *fp, const void *buff, unsigned int size)
{
	unsigned int i;
	const uint8_t *b = (uint8_t *)buff;
	char ascii[17];
	char str[2] = { 0x0, };

	if (size == 0)
		return;

	for (i = 0; i < size; i++) {
		if ((i & 0x0f) == 0x00) {
			fprintf(fp, " %08x:", i);
			memset(ascii, 0, sizeof(ascii));
		}
		fprintf(fp, " %02x", b[i]);
		str[0] = isalnum(b[i]) ? b[i] : '.';
		str[1] = '\0';
		strncat(ascii, str, sizeof(ascii) - 1);

		if ((i & 0x0f) == 0x0f)
			fprintf(fp, " | %s\n", ascii);
	}
	/* print trailing up to a 16 byte boundary. */
	for (; i < ((size + 0xf) & ~0xf); i++) {
		fprintf(fp, "   ");
		str[0] = ' ';
		str[1] = '\0';
		strncat(ascii, str, sizeof(ascii) - 1);

		if ((i & 0x0f) == 0x0f)
			fprintf(fp, " | %s\n", ascii);
	}
	fprintf(fp, "\n");
}

#endif		/* __DNUT_TOOLS_H__ */
