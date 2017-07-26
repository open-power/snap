# Several modes for snap_intersect

## With HW (simulation or real FPGA run)

	./snap_intersect -m1  (default using hash method)
	./snap_intersect -m2  (need to change the symbolic link of hw, pointint to hw_s)

## Run SW

	SNAP_CONFIG=1 ./snap_intersect -m0 -s  (software naive way for intersection)
	SNAP_CONFIG=1 ./snap_intersect -m1 -s  (software hash method)
	SNAP_CONFIG=1 ./snap_intersect -m2 -s  (software sort method)

	"-s" is needed. 
