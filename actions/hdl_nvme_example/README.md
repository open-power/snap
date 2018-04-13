# SNAP NVMe Block Layer

The SNAP NVMe block layer provides a shared library which is compatible to the IBM CapiFLASH block API (https://github.com/open-power/capiflash). The SNAP version does not implement the entire API, but instead just the bare minimum: cblk_open, cblk_close, cblk_read, cblk_write and cblk_get_lun_size. Currently just one of the NVMe devices is supported.

We created this library to explore potential performance improvements by doing transparent LBA prefetching. To get this working a small cache layer was added and, at this point in time, three pre-fetching strategies were added: UP, DOWN, UPDOWN. It is possible to set the number of LBAs per pre-fetch request. A threshold setting can suppress pre-fetching if the additional traffic on the NVMe device would have a negative impact on the overall performance of the solution.

# NVMe Hardware Action

The current hardware action supports 16 read/write request slots which operate in parallel. A single read-clear status register indicates that a request was completed successfully. The experiment focused on exploring the read behavior.

# Environment Variables to influence the behavior

* CBLK_PREFETCH: Number of LBAs to pre-fetch per block read request. Prefetching implies that caching will be enabled
* CBLK_STRATEGY: UP, DOWN, UPDOWN
  * UP: Fetching LBA + nblocks, LBA + 2 * nblocks, ...
  * DOWN: Fetching LBA - nblocks, LBA - 2 * nblocks, ...
  * UPDOWN: Fetching LBA - nblocks, LBA - 2 * nblocks, ..., LBA + nblocks, LBA + 2 * nblocks, ...
* CBLK_NBLOCKS: nblocks for the pre-fetching strategy
* CBLK_CACHING: 0 disables caching, for testing
* CBLK_BUSYTIMEOUT: Time in sec for a request to stay on the busy semaphore (exceeding the 16 possible read requests)
* CBLK_REQTIMEOUT: Timeout in sec for a hardware request to finish

