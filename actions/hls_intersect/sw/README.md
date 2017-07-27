# Several modes for snap_intersect


## With HW (simulation or real FPGA run)

	FPGA doing intersection step(1-3-5)
	(FPGA does memcopy in step1 and step5. FPGA does intersection in step3.) 
	./snap_intersect -m1  (hash method)
	./snap_intersect -m2  (sort method)

	CPU doing intersection step(1-2-4): 
	(FPGA does memcopy in step1 and step2. CPU does intersection in step4.) 
	./snap_intersect -m1 -s (hash method)
	./snap_intersect -m2 -s (sort method)


## Run SW

	SNAP_CONFIG=1 ./snap_intersect -m0 -s  (software naive way for intersection)
	SNAP_CONFIG=1 ./snap_intersect -m1 -s  (software hash method)
	SNAP_CONFIG=1 ./snap_intersect -m2 -s  (software sort method)
	"-s" is needed. 

## Other arguments please look in `./snap_intersect -h`

