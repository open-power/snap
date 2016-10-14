#ifndef __DONUT_INTERNAL_H__
#define __DONUT_INTERNAL_H__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

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
