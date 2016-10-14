#ifndef __DONUT_INTERNAL_H__
#define __DONUT_INTERNAL_H__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __unused
#  define __unused __attribute__((unused))
#endif

/* General ACTION registers */
#define	ACTION_BASE		0x10000
#define	ACTION_CONTROL		ACTION_BASE
#define	ACTION_CONTROL_START	  0x00000001
#define	ACTION_CONTROL_IDLE	  0x00000004
#define	ACTION_CONTROL_RUN	  0x00000008

/* ACTION Specific register setup: Input */
#define ACTION_PARAMS_IN	(ACTION_BASE + 0x80) /* 0x80 - 0x90 */
#define ACTION_JOB_IN		(ACTION_BASE + 0x90) /* 0x90 - 0xfc */

/* ACTION Specific register setup: Output */
#define ACTION_PARAMS_OUT	(ACTION_BASE + 0x100) /* 0x100 - 0x110 */
#define ACTION_RETC		(ACTION_BASE + 0x104) /* 0x104 */
#define ACTION_JOB_OUT		(ACTION_BASE + 0x110) /* 0x110 - 0x1fc */

struct dnut_funcs {
	struct dnut_card * (* card_alloc_dev)(const char *path,
					      uint16_t vendor_id,
					      uint16_t device_id);
	int (* mmio_write32)(struct dnut_card *card,
			     uint64_t offset,
			     uint32_t data);
	int (* mmio_read32)(struct dnut_card *card, uint64_t offset,
			    uint32_t *data);
	int (* mmio_write64)(struct dnut_card *card, uint64_t offset,
			     uint64_t data);
	int (* mmio_read64)(struct dnut_card *card, uint64_t offset,
			    uint64_t *data);
	void (* card_free)(struct dnut_card *card);
};

/**
 * Register a software version of the FPGA action to enable us
 * simulating high-level behavior of the same and allowing us to
 * implement the host applications even before the real hardware
 * implementation is completely working.
 */
struct dnut_action {
	uint16_t vendor_id;
	uint16_t device_id;
	uint16_t action_type;
	unsigned int instances;
	struct dnut_funcs *funcs;
	struct dnut_action *next;
};

int dnut_action_register(struct dnut_action *action);

#ifdef __cplusplus
}
#endif

#endif	/* __DONUT_INTERNAL_H__ */
