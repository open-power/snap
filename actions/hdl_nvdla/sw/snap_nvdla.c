/*
 * Copyright 2018 International Business Machines
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

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <unistd.h>
#include <sys/time.h>
#include <getopt.h>
#include <ctype.h>

#include <libsnap.h>
#include <snap_tools.h>
#include <snap_s_regs.h>

#include "snap_nvdla.h"

/*  defaults */
#define MEGAB       (1024*1024ull)
#define GIGAB       (1024 * MEGAB)
#define DDR_MEM_SIZE    (4 * GIGAB)     /* 4 GB (DDR RAM) */
#define DDR_MEM_BASE_ADDR   0x00000000  /* Start of FPGA Interconnect */
#define ACTION_WAIT_TIME	1	/* Default in sec */

#define VERBOSE0(fmt, ...) do {         \
        printf(fmt, ## __VA_ARGS__);    \
    } while (0)

#define VERBOSE1(fmt, ...) do {         \
        if (verbose_level > 0)          \
            printf(fmt, ## __VA_ARGS__);    \
    } while (0)

#define VERBOSE2(fmt, ...) do {         \
        if (verbose_level > 1)          \
            printf(fmt, ## __VA_ARGS__);    \
    } while (0)


#define VERBOSE3(fmt, ...) do {         \
        if (verbose_level > 2)          \
            printf(fmt, ## __VA_ARGS__);    \
    } while (0)

#define VERBOSE4(fmt, ...) do {         \
        if (verbose_level > 3)          \
            printf(fmt, ## __VA_ARGS__);    \
    } while (0)

static const char* version = GIT_VERSION;
static  int verbose_level = 0;

//static uint64_t get_usec (void)
//{
//    struct timeval t;
//
//    gettimeofday (&t, NULL);
//    return t.tv_sec * 1000000 + t.tv_usec;
//}
//
//static void print_time (uint64_t elapsed, uint64_t size)
//{
//    int t;
//    float fsize = (float)size / (1024 * 1024);
//    float ft;
//
//    if (elapsed > 10000) {
//        t = (int)elapsed / 1000;
//        ft = (1000 / (float)t) * fsize;
//        VERBOSE1 (" end after %d msec (%0.3f MB/sec)\n" , t, ft);
//    } else {
//        t = (int)elapsed;
//        ft = (1000000 / (float)t) * fsize;
//        VERBOSE1 (" end after %d usec (%0.3f MB/sec)\n", t, ft);
//    }
//}
//
//static void* alloc_mem (int align, int size)
//{
//    void* a;
//    int size2 = size + align;
//
//    VERBOSE2 ("%s Enter Align: %d Size: %d (malloc Size: %d)\n",
//              __func__, align, size, size2);
//
//    if (posix_memalign ((void**)&a, 4096, size2) != 0) {
//        perror ("FAILED: posix_memalign()");
//        return NULL;
//    }
//
//    VERBOSE2 ("%s Exit %p\n", __func__, a);
//    return a;
//}
//
//static void free_mem (void* a)
//{
//    VERBOSE2 ("Free Mem %p\n", a);
//
//    if (a) {
//        free (a);
//    }
//}
//
//static void memset2 (void* a, uint64_t pattern, int size)
//{
//    int i;
//    uint64_t* a64 = a;
//
//    for (i = 0; i < size; i += 8) {
//        *a64 = (pattern & 0xffffffff) | (~pattern << 32ull);
//        a64++;
//        pattern += 8;
//    }
//}
//
/* Action or Kernel Write and Read are 32 bit MMIO */
static void action_write (struct snap_card* h, uint32_t addr, uint32_t data)
{
    int rc;

    rc = snap_mmio_write32 (h, (uint64_t)addr, data);

    if (0 != rc) {
        VERBOSE0 ("Write MMIO 32 Err\n");
    }

    return;
}

///*  Calculate msec to FPGA ticks.
// *  we run at 250 Mhz on FPGA so 4 ns per tick
// */
//static uint32_t msec_2_ticks (int msec)
//{
//    uint32_t fpga_ticks = msec;
//
//    fpga_ticks = fpga_ticks * 250;
//#ifndef _SIM_
//    fpga_ticks = fpga_ticks * 1000;
//#endif
//    VERBOSE1 (" fpga Ticks = %d (0x%x)", fpga_ticks, fpga_ticks);
//    return fpga_ticks;
//}
//
///*
// * Return 0 if buffer is equal,
// * Return index+1 if not equal
// */
//static int memcmp2 (uint8_t* src, uint8_t* dest, int len)
//{
//    int i;
//
//    for (i = 0; i < len; i++) {
//        if (*src != *dest) {
//            return i + 1;
//        }
//
//        src++;
//        dest++;
//    }
//
//    return 0;
//}

static void usage (const char* prog)
{
    VERBOSE0 ("SNAP NVDLA demo.\n"
              "    %s --loadable <loadable> --image <image> --rawdump\n",
              prog);
    VERBOSE0 ("Usage: %s\n"
              "    -h, --help           print usage information\n"
              "    -v, --verbose        verbose mode\n"
              "    -C, --card <cardno>  use this card for operation\n"
              "    -V, --version\n"
              "    -q, --quiet          quiece output\n"
              "    -t, --timeout        Timeout after N sec (default 1 sec)\n"
              "    -I, --irq            Enable Action Done Interrupt (default No Interrupts)\n"
              "    --loadable <loadable> input loadable file\n"
              "    --image <file>        input jpg/pgm file\n"
              "    --normalize <value>   normalize value for input image\n"
              "    --rawdump             dump raw dimg data\n"
              , prog);
}

int main (int argc, char* argv[])
{
    char device[64];
    struct snap_card* dn;   /* lib snap handle */
    int card_no = 0;
    int cmd;
    int rc = 1;
    uint64_t cir;
    int timeout = ACTION_WAIT_TIME;
    snap_action_flag_t attach_flags = 0;
    unsigned long ioctl_data;
    unsigned long dma_align;
    unsigned long dma_min_size;
    //struct snap_action *act = NULL;
    char card_name[16];   /* Space for Card name */
    char default_loadable[] = "./basic.nvdla";
    char default_image   [] = "./something.pgm";
    char default_input   [] = "./";
    char* loadable= NULL;
    char* image   = NULL;
    char* input   = NULL;
    int normalize = 0;
    int rawdump = 0;

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            { "card",     required_argument, NULL, 'C' },
            { "verbose",  no_argument,       NULL, 'v' },
            { "help",     no_argument,       NULL, 'h' },
            { "version",  no_argument,       NULL, 'V' },
            { "quiet",    no_argument,       NULL, 'q' },
            { "loadable", required_argument, NULL, 'l' },
            { "image",    required_argument, NULL, 'm' },
            { "input",    required_argument, NULL, 'i' },
            { "rawdump",  no_argument, NULL, 'r' },
            { "normalize",required_argument, NULL, 'n' },
            { "timeout",  required_argument, NULL, 't' },
            { "irq",      no_argument,       NULL, 'I' },
            { 0,          no_argument,       NULL, 0   },
        };
        cmd = getopt_long (argc, argv, "C:l:m:i:r:n:t:IqvVh",
                           long_options, &option_index);

        if (cmd == -1) { /* all params processed ? */
            break;
        }

        switch (cmd) {
        case 'v':   /* verbose */
            verbose_level++;
            break;

        case 'V':   /* version */
            VERBOSE0 ("%s\n", version);
            exit (EXIT_SUCCESS);;

        case 'h':   /* help */
            usage (argv[0]);
            exit (EXIT_SUCCESS);;

        case 'C':   /* card */
            card_no = strtol (optarg, (char**)NULL, 0);
            break;

        case 'l':
            loadable = optarg;
            break;

        case 'i':
            input = optarg;
            break;

        case 'm':
            image = optarg;
            break;

        case 'n':
            normalize = strtol (optarg, (char**)NULL, 0);
            break;

        case 'r':
            rawdump = 1;
            break;

        case 't':
            timeout = strtol (optarg, (char**)NULL, 0); /* in sec */
            break;

        case 'I':      /* irq */
            attach_flags = SNAP_ACTION_DONE_IRQ | SNAP_ATTACH_IRQ;
            break;

        default:
            usage (argv[0]);
            exit (EXIT_FAILURE);
        }
    }

    if (loadable == NULL) {
        loadable = (char*) default_loadable;
    }

    if (input == NULL) {
        input = (char*) default_input;
    }

    if (image == NULL) {
        image = (char*) default_image;
    }

    if (card_no > 4) {
        usage (argv[0]);
        exit (1);
    }

    sprintf (device, "/dev/cxl/afu%d.0s", card_no);
    VERBOSE2 ("Open Card: %d device: %s\n", card_no, device);
    dn = snap_card_alloc_dev (device, SNAP_VENDOR_ID_ANY, SNAP_DEVICE_ID_ANY);

    if (NULL == dn) {
        VERBOSE0 ("ERROR: Can not Open (%s)\n", device);
        errno = ENODEV;
        perror ("ERROR");
        return -1;
    }

    /* Read Card Name */
    snap_card_ioctl (dn, GET_CARD_NAME, (unsigned long)&card_name);
    VERBOSE1 ("SNAP on %s", card_name);

    snap_card_ioctl (dn, GET_SDRAM_SIZE, (unsigned long)&ioctl_data);
    VERBOSE1 (" Card, %d MB of Card Ram avilable. ", (int)ioctl_data);

    snap_card_ioctl (dn, GET_DMA_ALIGN, (unsigned long)&dma_align);
    VERBOSE1 (" (Align: %d ", (int)dma_align);

    snap_card_ioctl (dn, GET_DMA_MIN_SIZE, (unsigned long)&dma_min_size);
    VERBOSE1 (" Min DMA: %d Bytes)\n", (int)dma_min_size);

    snap_mmio_read64 (dn, SNAP_S_CIR, &cir);
    VERBOSE1 ("Start NVDLA in Card Handle: %p Context: %d\n", dn,
              (int) (cir & 0x1ff));

    snap_attach_action(dn, ACTION_TYPE_NVDLA,
            attach_flags, 5 * timeout);

    VERBOSE1 ("Turn on the NVDLA register region\n");
    // Enable the NVDLA register region
    action_write(dn, ACTION_CONFIG, 0x00000100);

    VERBOSE1 ("Start to run NVDLA\n");
    nvdla_probe(dn);
    nvdla_capi_test(loadable, input, image, normalize, rawdump);
    VERBOSE1 ("Stop to run NVDLA\n");

    VERBOSE1 ("Turn off the NVDLA register region\n");
    // Disable the NVDLA register region
    action_write(dn, ACTION_CONFIG, 0x00000000);

    // Unmap AFU MMIO registers, if previously mapped
    VERBOSE2 ("Free Card Handle: %p\n", dn);
    snap_card_free (dn);

    VERBOSE1 ("End of Test rc: %d\n", rc);
    return rc;
}
