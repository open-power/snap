#ifndef __DONUT_INTERNAL_H__
#define __DONUT_INTERNAL_H__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __unused
#  define __unused __attribute__((unused))
#endif

#ifndef ARRAY_SIZE
#  define ARRAY_SIZE(a)  (sizeof((a)) / sizeof((a)[0]))
#endif

#ifndef ABS
#  define ABS(a)	 (((a) < 0) ? -(a) : (a))
#endif

#ifndef MAX
#  define MAX(a,b)	({ __typeof__ (a) _a = (a); \
			   __typeof__ (b) _b = (b); \
			   (_a) > (_b) ? (_a) : (_b); })
#endif

#ifndef MIN
#  define MIN(a,b)	({ __typeof__ (a) _a = (a); \
			   __typeof__ (b) _b = (b); \
			   (_a) < (_b) ? (_a) : (_b); })
#endif

#define	CACHELINE_BYTES		128

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
	void * (* card_alloc_dev)(const char *path, uint16_t vendor_id,
				  uint16_t device_id);
	int (* mmio_write32)(void *card, uint64_t offset, uint32_t data);
	int (* mmio_read32)(void *card, uint64_t offset, uint32_t *data);
	int (* mmio_write64)(void *card, uint64_t offset, uint64_t data);
	int (* mmio_read64)(void *card, uint64_t offset, uint64_t *data);
	void (* card_free)(void *card);
};

int action_trace_enabled(void);

#define act_trace(fmt, ...) do {					\
		if (action_trace_enabled())				\
			fprintf(stderr, "A " fmt, ## __VA_ARGS__);	\
	} while (0)

/**
 * Register a software version of the FPGA action to enable us
 * simulating high-level behavior of the same and allowing us to
 * implement the host applications even before the real hardware
 * implementation is completely working.
 */
enum dnut_action_state {
	ACTION_IDLE = 0,
	ACTION_RUNNING,
	ACTION_ERROR,
};

struct dnut_action;

typedef int (*action_main_t)(struct dnut_action *action,
			     void *job, unsigned int job_len);

struct dnut_action {
	uint16_t vendor_id;
	uint16_t device_id;
	uint16_t action_type;

	enum dnut_action_state state;
	struct dnut_funcs *funcs;
	void *priv_data;
	uint8_t job[CACHELINE_BYTES];
	uint32_t retc;
	action_main_t main;

	struct dnut_action *next;
};

int dnut_action_register(struct dnut_action *action);

#ifdef __cplusplus
}
#endif

#endif	/* __DONUT_INTERNAL_H__ */
