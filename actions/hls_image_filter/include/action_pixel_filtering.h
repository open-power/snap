#ifndef __PIXEL_FILTER_H__
#define __PIXEL_FILTER_H__

/*
 * Copyright 2020 International Business Machines
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

#include <snap_types.h>

#ifdef __cplusplus
extern "C" {
#endif

/* This number is unique and is declared in ~snap/ActionTypes.md */
#define IMAGE_FILTERING_ACTION_TYPE 0x1014100D

/**********************************************************************
 * BITMAPTYPES
 *********************************************************************/
#define BM_4x2				0 /* Bitmap 4x2 */


typedef struct pixel {
  uint8_t alpha;
  uint8_t red;
  uint8_t green;
  uint8_t blue;
} pixel_t;
  
/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct image_filtering_job {
	struct snap_addr in;		/* input data */
	struct snap_addr out;		/* offset table */
	uint32_t totalFileSizeFromHeader;  		/* for alignment purpose */
	uint8_t firstPixelRelLoc;		/* from bmp header */
	uint8_t dummy_pixel_8;  		/* for alignment purpose */
	uint16_t dummy_pixel_16;  		/* for alignment purpose */
	uint32_t pixel_map_type;		/* organisation of pixels definition */
	uint32_t dummy_pixel_32;  		/* for alignment purpose */	
} image_filtering_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __PIXEL_FILTER_H__ */
