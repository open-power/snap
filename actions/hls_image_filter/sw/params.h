#ifndef _PARAM_H_  // prevent recursive inclusion
#define _PARAM_H_

#include <fcntl.h>
#include <stdio.h> 
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <getopt.h>
#include <malloc.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <assert.h>
#include <snap_tools.h>
#include <libsnap.h>
#include <action_pixel_filtering.h>
#include "../include/action_pixel_filtering.h"
#include <snap_hls_if.h>

typedef struct { 
      uint16_t card_no;
      char *input;
      char *output;
      uint8_t addr_in;
	  uint8_t addr_out;
	  uint8_t type_in;
      uint8_t type_out;
      unsigned long timeout;
      int verify;
	  snap_action_flag_t action_irq;
	  int verbose_flag;
}
STRparam;

void usage(const char *prog);
STRparam* readParams(int argc, char *argv[]);

static STRparam parms;
	

#endif	
