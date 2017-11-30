# SNAP NVMe Blocklayer

The SNAP NVMe blocklayer provides a shared library which is compatible to the IBM CapiFLASH block API (https://github.com/open-power/capiflash). The SNAP version does not implement the entire API, but instead just the bare minimum: cblk_open, cblk_close, cblk_read, cblk_write and cblk_get_lun_size. Currently just one of the NVMe devices is supported.

We created this library to explore potential performance improvements by doing transparent LBA prefetching. To get this working a small cache layer was added and, at this point in time, three pre-fetching strategies were added: UP, DOWN, UPDOWN. Also it is possible to set the number of LBAs per pre-fetch request and a threshold used to supress pre-fetching if the traffic on the NVMe device should be too high, such that pre-fetching would have negetive influence on the achievable performance of the solution.

# NVMe Hardware Action

The current hardware action supports 15 read request slots, which can be operated in parallel. There is one read-clear status register which is used to determine if a request has been successfully completed. There is just one write request slot, which might be a deficience to get maximum write throughput. The focus of this experiment was on exploring the behavior on reads.

# Environment Variables to influence the behavior

* CBLK_PREFETCH: Number of LBAs to be pre-fetched per block read request, prefetching implies that caching will be enabled
* CBLK_STRATEGY: UP, DOWN, UPDOWN
  * UP: Fetching LBA + nblocks, LBA + 2 * nblocks, ...
  * DOWN: Fetching LBA - nblocks, LBA - 2 * nblocks, ...
  * UPDOWN: Fetching LBA - nblocks, LBA - 2 * nblocks, ..., LBA + nblocks, LBA + 2 * nblocks, ...
* CBLK_NBLOCKS: nblocks for the pre-fetching strategy
* CBLK_CACHING: 0 disables caching, for testing
* CBLK_BUSYTIMEOUT: Time in sec for a request to stay on the busy semaphore (exceeding the 15 possible read requests)
* CBLK_REQTIMEOUT: Timeout in sec for a hardware request to finish
