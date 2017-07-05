/*
 * Copyright 2017 International Business Machines
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

/*
 * SNAP NVME Maintenance tool Written by Eberhard S. Amann esa@de.ibm.com.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <signal.h>
#include <stdbool.h>
#include <unistd.h>
#include <errno.h>
#include <getopt.h>
#include <endian.h>
#include <sys/stat.h>

#include <libcxl.h>

#include <snap_internal.h>
#include <libsnap.h>
#include <snap_tools.h>
#include <snap_m_regs.h>

static const char *version = GIT_VERSION;
static int verbose = 0;
static FILE *fd_out;

#define VERBOSE0(fmt, ...) do {					\
		fprintf(fd_out, fmt, ## __VA_ARGS__);		\
	} while (0)

#define VERBOSE1(fmt, ...) do {					\
		if (verbose > 0)				\
			fprintf(fd_out, fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE2(fmt, ...) do {					\
		if (verbose > 1)				\
			fprintf(fd_out, fmt, ## __VA_ARGS__);	\
	} while (0)

#define VERBOSE3(fmt, ...) do {					\
		if (verbose > 2)				\
			fprintf(fd_out, fmt, ## __VA_ARGS__);	\
	} while (0)

#define MAX_SNAP_DRIVES       2
#define DRIVE0_AQ_PTR_START   0x0000 /* 0x0000 -> 0x0040 -> 0x0080 -> 0x00c0 */
#define DRIVE1_AQ_PTR_START   0x3780 /* 0x3780 -> 0x37c0 -> 0x3800 -> 0x3840 */
#define ADMIN_Q_ENTRIES       4

/* NVMe Admin Register */
#define ADMIN_CONTROL_REG     0x80    /* Admin Control Register */
#define ADMIN_CONTROL_ENA     0x01    /* Enable NVMe Host */
#define ADMIN_CONTROL_EAINC   0x02    /* Enable Auto-increment Addressing */
#define ADMIN_CONTROL_CES     0x04    /* Clear Error Status */

#define ADMIN_STATUS_REG      0x84    /* Admin Status Register */
#define ADMIN_STATUS_REDAY    0x01    /* NVMe Host Ready */
#define ADMIN_STATUS_ERROR    0x02    /* Error Error Condition Detected */
#define ADMIN_STATUS_SSD0     0x04    /* Admin Command to SSD0 Complete */
#define ADMIN_STATUS_SSD1     0x08    /* Admin Command to SSD1 Complete */

#define ADMIN_BUFFER_ADDR_REG 0x88    /* Buffer Address for accessing buffer data */
#define ADMIN_PCIE_ADDR_REG   0x8c    /* PCIe address for accessing PCIe space */
#define ADMIN_NSID_REG        0x90    /* NVMe Namespace ID */
#define ADMIN_ASQ_INDEX_REG   0x94    /* Admin Sub. queue Indexes */
#define ADMIN_ASQ_INDEX_SSD0  0xFF    /* Bits 0 : 7 SSD0 Index (we use 0:2) */
#define ADMIN_ASQ_INDEX_SSD1  0xFF0000 /* Bits 23:16 SSD1 Index (we use 18:16 */
#define ADMIN_SCRATCH_REG     0x98    /* Scratch Reg */

#define DEFAULT_WAIT_US       1000     /* usec to wait */

struct pcie_tab {
	uint32_t addr;
	uint32_t data;
};

/*
 * Open AFU Master Device
 */
static void *snap_open(int card)
{
	char device[64];
	void *handle = NULL;

	sprintf(device, "/dev/cxl/afu%d.0m", card);
	VERBOSE3("[%s] Enter: %s\n", __func__, device);
	handle = snap_card_alloc_dev(device, SNAP_VENDOR_ID_IBM,
		SNAP_DEVICE_ID_SNAP);
	VERBOSE3("[%s] Exit %p\n", __func__, handle);
	return handle;
}

static void snap_close(void *handle)
{
	VERBOSE3("[%s] Enter\n", __func__);
	if (handle)
		snap_card_free(handle);
	VERBOSE3("[%s] Exit\n", __func__);
	return;
}

/*
 * Class AFU_MMIO
 */
static uint32_t MMIO_read(void *handle, uint32_t addr)
{
	uint32_t reg;
	int rc;

	rc = snap_mmio_read32(handle, (uint64_t)addr, &reg);
	if (0 != rc)
		VERBOSE0("[%s] Error Addr %x\n", __func__, addr);
	return reg;
}

static void MMIO_write(void *handle, uint32_t addr, uint32_t data)
{
	int rc;

	rc = snap_mmio_write32(handle, (uint64_t)addr, data);
	if (0 != rc)
		VERBOSE0("[%s] Error Addr: %x\n", __func__, addr);
	return;
}

static void nvme_write(void * handle, uint32_t addr, uint32_t data)
{
	if (addr >= 0x30000) {
		MMIO_write(handle, 0x30000, addr);
		addr = 0x30004;
	} else addr = 0x20000 + addr;
	MMIO_write(handle, addr, data);
}

static uint32_t nvme_read(void *handle, uint32_t addr)
{
	uint32_t data;

	if (addr >= 0x30000) {
		MMIO_write(handle, 0x30000, addr);
		addr = 0x30004;
	} else addr = 0x20000 + addr;
	data = MMIO_read(handle, addr);
	return data;
}

static void nvme_fill_buffer(void *handle, uint32_t *buffer, int size)
{
	int i;

	VERBOSE2("[%s] Enter from Data @: %p Size: %d Bytes\n", __func__, buffer, size);
	/* Set Auto increment, Enable NVME Host, Clear Error status */
	nvme_write(handle, ADMIN_CONTROL_REG,
		(ADMIN_CONTROL_ENA | ADMIN_CONTROL_CES | ADMIN_CONTROL_EAINC));
	for (i = 0 ; i < size; i++)
		nvme_write(handle, 0x100, *buffer++);
	VERBOSE2("[%s] Exit\n", __func__);
}

#define PROGRESS_ssd_0_initdone  0x01
#define PROGRESS_ssd_0_IOQueueUp 0x02
#define PROGRESS_ssd_1_initdone  0x04
#define PROGRESS_ssd_1_IOQueueUp 0x08

static uint64_t g_prog_reg;

static uint32_t get_prog_reg(void)
{
	return g_prog_reg;
}

static void set_prog_reg(uint64_t prog_reg)
{
	g_prog_reg = prog_reg;
}

static bool ssdinitdone(int drive)
{
	uint64_t prog_reg;
	uint64_t mask;

	prog_reg = get_prog_reg();
	if (0 == drive)
		mask = PROGRESS_ssd_0_initdone;
	else    mask = PROGRESS_ssd_1_initdone;
	if (prog_reg & mask)
		return true;
	return false;
}

static void set_ssdinitdone(int drive)
{
	uint64_t prog_reg;

	prog_reg = get_prog_reg();
	if (0 == drive)
		prog_reg |= PROGRESS_ssd_0_initdone;
	else    prog_reg |= PROGRESS_ssd_1_initdone;
	set_prog_reg(prog_reg);
}

static bool ssdIOQueueUp(int drive)
{
	uint64_t prog_reg;
	uint64_t mask;

	prog_reg = get_prog_reg();
	if (0 == drive)
		mask = PROGRESS_ssd_0_IOQueueUp;
	else    mask = PROGRESS_ssd_1_IOQueueUp;
	if (prog_reg & mask)
		return true;
	return false;
}

static void set_ssdIOQueueUp(int drive)
{
	uint64_t prog_reg;

	prog_reg = get_prog_reg();
	if (0 == drive)
		prog_reg |= PROGRESS_ssd_0_IOQueueUp;
	else    prog_reg |= PROGRESS_ssd_1_IOQueueUp;
	set_prog_reg(prog_reg);
}

/*
 * Bits in PROG_REG: 7 6    5 4    3   2   1   0
 *                   ---    ---   --  --  --  --
 *                                Q1  I1  Q0  I0
 *
 * Bit 3 I0 Drive 1 ssdIOQueueUp
 * Bit 2 Q0 Drive 1 ssdinitdone
 * Bit 1 I1 Drive 1 ssdIOQueueUp
 * Bit 0 Q1 Drive 0 ssdinitdone
 */
static void show_prog_reg(void)
{
	int i;

	for (i = 0; i < MAX_SNAP_DRIVES; i++)
		VERBOSE1("     SSD[%d] InitDone: %d QueueDone: %d\n",
			i, ssdinitdone(i), ssdIOQueueUp(i));
}

/*
 * Class: NVME_Drive
 */

static void drive_write(void *handle, int drive, uint32_t addr, uint32_t data)
{
	if (1 == drive)
		addr += 0x2000;
	MMIO_write(handle, 0x2008c, addr);
	MMIO_write(handle, 0x20104, data);
}

static uint32_t drive_read(void *handle, int drive, uint32_t addr)
{
	uint32_t data;

	if (1 == drive)
		addr += 0x2000;
	MMIO_write(handle, 0x2008c, addr);
	data = MMIO_read(handle, 0x20104);
	return data;
}

static int drive_wait_for_ready(void *handle, int drive)
{
	int i;
	uint32_t data;
	int rc = 1;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	for (i = 0; i < 100; i++) {
		data = drive_read(handle, drive, 0x0000001c);
		if (data) {
			rc = 0;
			break;
		}
		usleep(DEFAULT_WAIT_US);
	}
	if (0 != rc)
		VERBOSE0("     Error SSD[%d] Not Ready after %d Retries. 0x%x\n",
			drive, i, data);
	VERBOSE2("[%s] Exit SSD[%d] after: %d data: 0x%x rc: %d\n",
		__func__, drive, i, data, rc);
	return rc;
}

static int drive_wait_for_complete(void *handle, int drive)
{
	int i;
	uint32_t data, mask;
	int rc = 1;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	nvme_write(handle, ADMIN_CONTROL_REG,
		(ADMIN_CONTROL_ENA | ADMIN_CONTROL_CES));    /* Clear Error Bit */
	if (0 == drive)
		mask = ADMIN_STATUS_SSD0;
	else    mask = ADMIN_STATUS_SSD1;

	for (i = 0; i < 100; i++) {
		data = nvme_read(handle, ADMIN_STATUS_REG);
		if (data & ADMIN_STATUS_ERROR) {
			VERBOSE0("   Error: SSD[%d] waiting for Admin Command to complete: 0x%x\n",
				drive, data);
			break;
		}
		if (data & mask) {
			rc = 0;     /* OK */
			break;
		}
		usleep(DEFAULT_WAIT_US);
	}
	if (0 != rc)
		VERBOSE0("     Error: SSD[%d] Not Ready after %d Retries. Status Reg: 0x%x\n",
			drive, i, data);
	VERBOSE2("[%s] Exit SSD[%d] Data: 0x%x rc: %d\n",
		__func__, drive, data, rc);
	return rc;
}

static uint32_t drive_get_aq_ptr(void * handle, int drive)
{
	uint32_t index;
	uint32_t aq_ptr = DRIVE0_AQ_PTR_START;

	index = nvme_read(handle, ADMIN_ASQ_INDEX_REG);
	if (1 == drive) {
		index = index >> 16;
		aq_ptr =  DRIVE1_AQ_PTR_START;
	}
	aq_ptr += (index & 0x3) * 0x40;
	VERBOSE2("[%s] SSD[%d] Index: %d AQ_Ptr: 0x%4.4x\n",
		__func__, drive, index, aq_ptr);
	return aq_ptr;
}

static int drive_exec(void * handle, int drive, uint32_t *data)
{
	int rc;
	uint32_t cmd, offset;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	offset = drive_get_aq_ptr(handle, drive);
	nvme_write(handle, ADMIN_BUFFER_ADDR_REG, offset);
	nvme_fill_buffer(handle, data, 16);
	cmd = 0x2 + (drive * 0x20);
	nvme_write(handle, 0x14, cmd);
	rc = drive_wait_for_complete(handle, drive);
	VERBOSE2("[%s] Exit SSD[%d] rc: %d\n", __func__, drive, rc);
	return rc;
}

static uint32_t create_io_q1_data[2][16] = {
	{0x00005,0,0,0,0,0,0x38000000,0,0,0,0xd90001,1,0,0,0,0},
	{0x20005,0,0,0,0,0,0x48000000,0,0,0,0xd90001,1,0,0,0,0},
};
static uint32_t create_io_q2_data[2][16] = {
	{0x00001,0,0,0,0,0,0x10000000,0,0,0,0xd90001,0x10005,0,0,0,0},
	{0x20001,0,0,0,0,0,0x20000000,0,0,0,0xd90001,0x10005,0,0,0,0},
};
static int create_io_queues(void *handle, int drive)
{
	int rc = 0;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	rc = drive_exec(handle, drive,  &create_io_q1_data[drive][0]);
	if (0 == rc)
		rc = drive_exec(handle, drive,  &create_io_q2_data[drive][0]);
	VERBOSE2("[%s] Exit rc: %d\n", __func__, rc);
	return rc;
}

#if 0
static uint32_t send_identify_data[2][16] = {
	{0x00006,0,0,0,0,0,0x50000000,0,0,0,1,0,0,0,0,0},
	{0x20006,0,0,0,0,0,0x50000000,0,0,0,1,0,0,0,0,0},
};
static int drive_send_identify(void *handle, int drive)
{
	int rc;

	VERBOSE2("[%s] Enter SSD%d\n", __func__, drive);
	rc = drive_exec(handle, drive, &send_identify_data[drive][0]);
	VERBOSE2("[%s] Exit rc: %d\n", __func__, rc);
	return rc;
}
#endif

static uint32_t send_identify_data2[2][16] = {
	{0x00006,1,0,0,0,0,0x50000000,0,0,0,0,0,0,0,0,0},
	{0x20006,1,0,0,0,0,0x50000000,0,0,0,0,0,0,0,0,0},
};
static int drive_send_identify2(void *handle, int drive)
{
	int rc;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	rc = drive_exec(handle, drive, &send_identify_data2[drive][0]);
	VERBOSE2("[%s] Exit rc: %d\n", __func__, rc);
	return rc;
}

#if 0
static uint32_t get_log_data[2][16] = {
	{0x00002,0,0,0,0,0,0x50000000,0,0,0,1,2,0,0,0,0},
	{0x20002,0,0,0,0,0,0x50000000,0,0,0,0x00ff0001,0,0,0,0,0}
}
static void get_log(void *handle, int drive)
{
	int rc;

	VERBOSE2("[%s] Enter SSD%d\n", __func__, drive);
	rc = drive_exec(handle, drive, &sget_log_data[drive][0]);
	VERBOSE2("[%s] Exit rc: %d\n", __func__, rc);
	return rc;
}
#endif

static uint32_t set_features_data[2][16] = {
	{0x00009,0,0,0,0,0,0,0,0,0,1,2,0,0,0,0},
	{0x20009,0,0,0,0,0,0,0,0,0,1,2,0,0,0,0},
};
static int drive_set_features(void *handle, int drive)
{
	int rc;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	rc = drive_exec(handle, drive, &set_features_data[drive][0]);
	VERBOSE2("[%s] Exit rc: %d\n", __func__, rc);
	return rc;
}

static uint32_t get_features_data[2][16] = {
	{0x0000a,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0},
	{0x2000a,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0},
};
static int drive_get_features(void *handle, int drive)
{
	int rc;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	rc = drive_exec(handle, drive, &get_features_data[drive][0]);
	VERBOSE2("[%s] Exit rc: %d\n", __func__, rc);
	return rc;
}

#if 0
static void drive_dump_buffer(void *handle, int n)
{
	uint32_t data;

	nvme_write(handle, ADMIN_BUFFER_ADDR_REG, 0x6f0);
	while (n--) {
		data = nvme_read(handle, 0x100);
		VERBOSE1("Buffer data word %d : 0x%x\n", n, data);
	}
}
#endif

static int wait_pcie_link_up(void *handle, int drive)
{
	int rc = 1;
	uint32_t addr, data, offset;
	int width, i, ltssm_state;

	offset = 0;    /* for drive 0 */
	if (1 == drive)
		offset = 0x10000000;  /* for drive 1 */
	addr = 0x10000144 + offset;
	data = nvme_read(handle, addr);
	/* Decode Status */
	VERBOSE1("SSD[%d] PCIE ", drive);
	/* Wait Until PCIE Link is up */
	for (i = 0; i < 80; i++) {
		data = nvme_read(handle, addr);
		/* Decode PCIE State Machine state */
		ltssm_state = (data & 0x1f8) >> 3;
		VERBOSE2("\nSSD[%d] (%2.2d) PCIE State: %2.2d",
			drive, i, ltssm_state);
		if (0x800 & data) {    /* Check for Link Up */
			VERBOSE1(" -> UP (after %d sec).\n", i*2);
			rc = 0;
			break;
		}
		sleep(2);
	}
	VERBOSE1("SSD[%d] PCIE Link Rate: ", drive);
	if (0x1000 & data)
		VERBOSE1("Gen3");
	else {
		if (0x1 & data)
			VERBOSE1("Gen2 @ 5 GT/s");
		else    VERBOSE1("Gen2 @ 2.5 GT/s");
	}
	width = (data & 0x6) >> 1;
	VERBOSE1(" Link With: ");
	switch (width) {
		case 0: VERBOSE1("1\n"); break;
		case 1: VERBOSE1("2\n"); break;
		case 2: VERBOSE1("4\n"); break;
		case 3: VERBOSE1("8\n"); break;
	}
	if (0 != rc)
		VERBOSE0("Error: PCIE Link Reports: 0x%8.8x\n", data);
	return rc;
}

/*
 *  End of Class NVME_Drive
 */

struct pcie_tab pcie_setup_data[] = {
	{0x10000018, 0x00010100},     /* set bus, devive and function number */
	{0x100000d4, 0x00000000},     /* set device capabilities */
	{0x10100010, 0x6000000c},     /* PCIe Base Addr Register 0  */
	{0x10100014, 0x00000000},     /* PCIe Base Addr Register 1 */
	{0x10100018, 0x00000000},     /* PCIe Base Addr Register 2 */
	{0x1010001c, 0x00000000},     /* PCIe Base Addr Register 3 */
	{0x10100020, 0x00000000},     /* PCIe Base Addr Register 4 */
	{0x10100024, 0x00000000},     /* PCIe Base Addr Register 5 */
	{0x10100030, 0x00000000},     /* Expansion ROM address */
	{0x101000d0, 0x00000041},     /* Telling endpoint what common clock and power management states are enable */
	{0x10100004, 0x00000006},     /* PCI command register */
	{0x10000148, 0x00000001},     /* PCI enable root port */
	{0x1000020c, 0x60000000},     /* set up AXI Base address translation register */
};
/*	PCIE Setup */
static void pcie_setup(void *handle, int drive)
{
	struct pcie_tab *p = &pcie_setup_data[0];
	uint32_t addr, offset;
	unsigned int i;

	VERBOSE2("[%s] Enter SSD[%d]...\n", __func__, drive);
	offset = 0;    /* for drive 0 */
	if (1 == drive)
		offset = 0x10000000;  /* Offset for SSD 1 */
	for (i = 0; i < ARRAY_SIZE(pcie_setup_data); i++) {
		addr = p->addr + offset;
		nvme_write(handle, addr, p->data);
		p++;
	}
	VERBOSE2("[%s] Exit SSD[%d]\n", __func__, drive);
	return;
}

static int nvme_init(void *handle, int drive)
{
	uint32_t drive_offset;
	uint32_t data, queue_entries, mps;
	int rc;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	if (1 == drive)
		drive_offset = 0x10000000;
	else drive_offset = 0;
	data = drive_read(handle, drive, 0x0000);
	VERBOSE1("           Cap Register(0): 0x%8.8x\n", data);
	data = drive_read(handle, drive, 0x0004);
	mps = (data >> 20) & 0xf;
	VERBOSE1("           Cap Register(4): 0x%8.8x Max Page Size: 0x%x\n",
		data, mps);
	data = (4 << 20) | (6 << 16) | (mps << 7);
	drive_write(handle, drive, 0x14, data);

	queue_entries = (((ADMIN_Q_ENTRIES - 1) << 16) | (ADMIN_Q_ENTRIES - 1));
	drive_write(handle, drive, 0x24, queue_entries);
	drive_write(handle, drive, 0x30, 0x30000000 + drive_offset);
	drive_write(handle, drive, 0x34, 0x0000);
	drive_write(handle, drive, 0x28, 0x8000000 + drive_offset);
	drive_write(handle, drive, 0x2c, 0x0000);
	drive_write(handle, drive, 0x14, data | 1); /* disable auto increment of NVMe host */
	rc = drive_wait_for_ready(handle, drive);
	VERBOSE2("[%s] Exit SSD[%d] rc: %d\n", __func__, drive, rc);
	return rc;
}

static int nvme_init2(void *handle, int drive)
{
	int rc = 0;
	uint32_t data;

	VERBOSE2("[%s] Enter SSD[%d]\n", __func__, drive);
	data = drive_read(handle, drive, 0x003c);
	VERBOSE1("     SSD[%d] Capability Register: 0x%x\n", drive, data);
	rc = drive_get_features(handle, drive);
	if (0 == rc)
		rc = drive_set_features(handle, drive);
	if (0 == rc)
		rc = drive_send_identify2(handle, drive);
	if (0 == rc) {
		if (!ssdIOQueueUp(drive)) {
			rc = create_io_queues(handle, drive);
			if (0 == rc) {
				set_ssdIOQueueUp(drive);
				drive_get_features(handle, drive);
			}
		}
	}
	VERBOSE2("[%s] SSD[%d] Exit rc: %d\n", __func__, drive, rc);
	return rc;
}

static void help(char *prog)
{
	printf("\n\tSNAP tool to Init NVME Drives.\n");
	printf("Usage: %s [-CvhV] [-d drive]\n"
		"\t-C, --card <num> Card to use (default 0)\n"
		"\t-V, --version  Print Version number\n"
		"\t-h, --help     this help message\n"
		"\t-v, --verbose  verbose mode, up to -vvv\n"
		"\t-d, --drive    Nvme Drive (0 or 1), default: 0 and 1\n\n",
	       prog);
}

/**
 * Get command line parameters and create the output file.
 */
int main(int argc, char *argv[])
{
	int rc = EXIT_SUCCESS;
	int ch;
	void *handle = NULL;
	int card = 0;        /* Default, Card 0 */
	int drive = 0;
	fd_out = stdout; /* Default */
	unsigned long have_nvme = 0;
	unsigned int drive_mask = 0x03;       /* Enable drive 0 and 1 bits in mask */
	unsigned int new_drive_mask = 0x00;

	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",       required_argument, NULL, 'C' },
			{ "version",    no_argument,       NULL, 'V' },
			{ "help",       no_argument,       NULL, 'h' },
			{ "verbose",    no_argument,       NULL, 'v' },
			{ "drive",      required_argument, NULL, 'd' },
			{ 0,		0,                 NULL,  0  }
		};
		ch = getopt_long(argc, argv, "C:d:Vhv",
			long_options, &option_index);
		if (-1 == ch)
			break;
		switch (ch) {
		case 'C':	/* --card */
			card = strtol(optarg, (char **)NULL, 0);
			if ((card < 0) || (card >= 4)) {
				fprintf(stderr, "Err: %d for option -C is invalid, please provide "
					"0..3!\n", card);
				exit(EXIT_FAILURE);
			}
			break;
		case 'V':	/* --version */
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
			break;
		case 'h':       /* help */
			help(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		case 'v':	/* --verbose */
			verbose++;
			break;
		case 'd':       /* drive */
			drive = strtol(optarg, NULL, 0);
			if ((drive > 1) || (drive < 0)) {
				fprintf(stderr, "Please provide correct "
					"SSD[%d] (Must be 0 or 1)\n", drive);
				exit(EXIT_FAILURE);
			}
			new_drive_mask |= 1 << drive;
			break;
		default:
			help(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	handle = snap_open(card);
	if (NULL == handle) {
		rc = ENODEV;
		goto __main_exit;
	}

	if (0 != new_drive_mask)
		drive_mask = new_drive_mask;

	/* Check if i do have NVME on this card */
	snap_card_ioctl(handle, GET_NVME_ENABLED, (unsigned long)&have_nvme);
	if (0 == have_nvme) {
		VERBOSE0("Error SNAP NVME is not enabled on CAPI Card %d!\n", card);
		rc = ENODEV;
		goto __main_exit1;
	}

	/* set Namespace Identifier to 1 */
	nvme_write(handle, ADMIN_NSID_REG, 1);
	/* enable NVMe host */
	nvme_write(handle, ADMIN_CONTROL_REG, ADMIN_CONTROL_ENA);

	/* Get Prog Reg */
	g_prog_reg = nvme_read(handle, ADMIN_SCRATCH_REG);

	for (drive = 0; drive < MAX_SNAP_DRIVES; drive++) {
		/* Check which drive to init */
		if (0 == (drive_mask & (1 << drive)))
			continue;
		VERBOSE1("Init SSD[%d]\n", drive);
		show_prog_reg();
		rc = wait_pcie_link_up(handle, drive);
		if (0 == rc) {
			/* Init NVME PCIe */
			if (false == ssdinitdone(drive)) {
				pcie_setup(handle, drive);
				rc = nvme_init(handle, drive);
				if (0 == rc)
					set_ssdinitdone(drive);
			}
			if (ssdinitdone(drive))
				rc = nvme_init2(handle, drive);
		}
	}

	/* Save Prog Reg */
	nvme_write(handle, ADMIN_SCRATCH_REG, g_prog_reg);
__main_exit1:
	VERBOSE1("Exit rc: %d\n", rc);

	snap_close(handle);
__main_exit:
	exit(rc);
}
