#ifndef __ACTION_SEARCH_H__
#define __ACTION_SEARCH_H__

/*
 * Copyright 2016, International Business Machines
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
#include <libdonut.h>

#define SEARCH_ACTION_TYPE	0x0005 // 0xC0FE

struct search_job {
	struct dnut_addr input;	 /* input data */
	struct dnut_addr output; /* offset table */
	struct dnut_addr pattern;
	uint64_t nb_of_occurrences;
	uint64_t next_input_addr;
	uint64_t mmio_din;	/* private settings for this action */
	uint64_t mmio_dout;	/* private settings for this action */
};

#endif	/* __ACTION_SEARCH_H__ */
