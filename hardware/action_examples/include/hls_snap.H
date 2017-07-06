#ifndef __HLS_SNAP_H__
#define __HLS_SNAP_H__

/*
 * Copyright 2017, International Business Machines
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

#include <stdint.h>
#include <string.h>
#include <ap_int.h>
#include <hls_stream.h>

/*
 * Hardware implementation is lacking some libc functions. So let us
 * replace those.
 */
#ifndef ULONG_MAX
#  define ULONG_MAX 0xFFFFFFFFUL /* gcc compiler but not HLS compiler */
#endif
#ifndef NULL
#  define NULL 0                 /* gcc compiler but not HLS compiler */
#endif

#if !defined(NO_SYNTH)
#  define printf(fmt, args...)
#  define fprintf(file, fmt, args...)
#  define __unused
#endif

#ifndef MIN
#  define MIN(x, y) ((x) < (y) ? (x) : (y))
#endif

#ifndef ARRAY_SIZE
#  define ARRAY_SIZE(a) (sizeof((a))/sizeof((a)[0]))
#endif

/* General memory Data Width is set as a parameter*/
#define MEMDW 512          // 512 or 128 // Bus width in bits for Host memory
#define BPERDW (MEMDW/8)   // Bytes per Data Word    if MEMDW=512 => BPERDW = 64
#define WPERDW (64/BPERDW) // Number of words per DW if MEMDW=512 => WPERDW =  1
#define ADDR_RIGHT_SHIFT 6
#define SNAP_HLS_JOBSIZE 108

typedef ap_uint<MEMDW> snap_membus_t;  /* snap memory access */
typedef ap_uint<64> snapu64_t;
typedef ap_uint<32> snapu32_t;
typedef ap_uint<16> snapu16_t;
typedef ap_uint<8> snapu8_t;
typedef ap_uint<1> snap_bool_t;

typedef struct {
        snapu8_t sat; // short action type
        snapu8_t flags;
        snapu16_t seq;
        snapu32_t Retc;
        snapu64_t Reserved; // Priv_data
} CONTROL;

typedef struct {
        snapu32_t action_type;   // 4 bytes
        snapu32_t release_level; // 4 bytes
} action_RO_config_reg;

/*
 * Instead of reading each snap_membus_t line individually, we try to
 * read always a 4KiB block and return the line from the internal buffer.
 * if the buffer is empty, we read the following 4KiB block from the bus
 * in a burst.
 *
 * FIXME No underrun or access out of bounds protection.
 */
#define SNAP_4KiB_WORDS (4096 / sizeof(snap_membus_t))

/*
 * We found that having the indexes here too large we got synthesis
 * warnings about critical path problems. So reducing this to
 * smaller values helped, but reduced the possible buffer memory
 * sizes.
 */
typedef struct snap_4KiB_t {
	snap_membus_t buf[SNAP_4KiB_WORDS]; /* temporary storage buffer */
	snap_membus_t *mem;                 /* source where data comes from */
	unsigned short max_lines;           /* size of the memory buffer */
	unsigned short m_idx;               /* read position for source */
	unsigned char b_idx;                /* read position for buffer */
} snap_4KiB_t;

static inline int snap_4KiB_empty(snap_4KiB_t *buf)
{
	return buf->b_idx == 0;
}

static inline void snap_4KiB_rinit(snap_4KiB_t *buf, snap_membus_t *mem,
				   unsigned short max_lines)
{
	buf->mem = mem;
	buf->max_lines = max_lines;
	buf->m_idx = 0;
	buf->b_idx = SNAP_4KiB_WORDS;
}

static inline void snap_4KiB_winit(snap_4KiB_t *buf, snap_membus_t *mem,
				   unsigned short max_lines)
{
	buf->mem = mem;
	buf->max_lines = max_lines;
	buf->m_idx = 0;
	buf->b_idx = 0;
}

/**
 * Reading beyond the available memory is blocked, buffer filling
 * is returned to keep code simple, and contains unuseable data.
 */
static inline void snap_4KiB_get(snap_4KiB_t *buf, snap_membus_t *line)
{
	if ((buf->m_idx == buf->max_lines) &&
	    (buf->b_idx == SNAP_4KiB_WORDS)) {
		*line = (snap_membus_t)-1;
		return;
	}
	/* buffer is empty, read in the next 4KiB */
	if (buf->b_idx == SNAP_4KiB_WORDS) {
		unsigned short tocopy =
			MIN(SNAP_4KiB_WORDS, buf->max_lines - buf->m_idx);

#if defined(CONFIG_4KIB_DEBUG)
		fprintf(stderr, "4KiB buffer %d lines, reading %d bytes\n",
			tocopy, tocopy * (int)sizeof(snap_membus_t));
#endif
		switch (tocopy) {
		case 0: /* NOTE: Avoid read/write 0 bytes, HLS bug */
			break;
		case  SNAP_4KiB_WORDS:
			memcpy(buf->buf, buf->mem + buf->m_idx,
			       SNAP_4KiB_WORDS * sizeof(snap_membus_t));
			break;
		default:
			memcpy(buf->buf, buf->mem + buf->m_idx,
			       tocopy * sizeof(snap_membus_t));
			break;
		}
		
		buf->m_idx += tocopy;
		buf->b_idx = 0; /* buffer is full again */
	}
	*line = buf->buf[buf->b_idx];
	buf->b_idx++;
}

/**
 * Writing beyond the available memory is blocked, still we accept
 * data in the local buffer, but that will not be written out.
 * Normally I would have written that with tocopy = MIN(free_lines, buf->b_idx)
 * but that produced hardware with bad timing.
 */
static inline void snap_4KiB_flush(snap_4KiB_t *buf)
{
	unsigned short free_lines = buf->max_lines - buf->m_idx;
	unsigned short tocopy = MIN(free_lines, buf->b_idx);

#if defined(CONFIG_4KIB_DEBUG)
	fprintf(stderr, "4KiB buffer %d lines, writing %d bytes "
		"free: %d bmax: %d mmax: %d\n",
		tocopy, tocopy * (int)sizeof(snap_membus_t),
		(int)free_lines, SNAP_4KiB_WORDS, buf->max_lines);
#endif
	switch (tocopy) {
	case 0: /* NOTE: Avoid read/write 0 bytes, HLS bug */
		break;
	case SNAP_4KiB_WORDS:
		memcpy(buf->mem + buf->m_idx, buf->buf,
		       SNAP_4KiB_WORDS * sizeof(snap_membus_t));
		break;
	default:
		memcpy(buf->mem + buf->m_idx, buf->buf,
		       tocopy * sizeof(snap_membus_t));
		break;
	}
	buf->m_idx += tocopy;
	buf->b_idx = 0;
}

static inline void snap_4KiB_put(snap_4KiB_t *buf, snap_membus_t line)
{
	/* buffer is full, flush the gathered 4KiB */
	if (buf->b_idx == SNAP_4KiB_WORDS) {
		snap_4KiB_flush(buf);
	}
	buf->buf[buf->b_idx] = line;
	buf->b_idx++;
}

#endif  /* __HLS_SNAP_H__ */
