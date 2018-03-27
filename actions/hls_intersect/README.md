
# Notice: 
**This example often does not meet timing (> 200ps negative slack) in bitstream generation. Running on FPGA hardware has passed for many times but it is NOT guaranteed.**

**:warning:WARNING** 

**Please don't use it as a testing example on FPGA hardware.**

It stays here as a HLS coding example to show how to make two implementations for a single target. It also shows how to invoke the hardware action several times from C main() function. 


=====================================================

# How to build

Intersection has two methods and are implemented in two Actions. 
One is in hw_h (hash, -m1) and one is in hw_s (sort, -m2).
You must configure it first (otherwise the default one is 'hash').

After `make snap_config`, do this particular step to select the method. (In case $ACTION_ROOT is not set, try to source snap_path.sh)

```
make clean

make -C $ACTION_ROOT config_h
 .or.
make -C $ACTION_ROOT config_s 

```

Then follow the normal flow
``` 
make model
 .or. 
make image
```


# How to run

- Step1: Copy Tables from Host memory to FPGA Card memory
- Step2: Copy Tables from FPGA Card memory to Host memory
- Step3: FPGA does table intersection (result is in FPGA Card memory)
- Step4: CPU  does table intersection
- Step5: Copy Result from FPGA Card memory to Host memory

Compare time "Step3+Step5"  .vs.  "Step2+Step4"


## With HW Action (simulation or real FPGA run)
    SNAP_CONFIG=0

	HW doing intersection step(1-3-5)
	(FPGA does memcopy in step1 and step5. FPGA does intersection in step3.) 
	./snap_intersect -m1  (hash method)
	./snap_intersect -m2  (sort method)

	CPU doing intersection step(1-2-4): 
	(FPGA does memcopy in step1 and step2. CPU does intersection in step4.) 
	./snap_intersect -m1 -s (hash method)
	./snap_intersect -m2 -s (sort method)


## Without HW Action (Only step4 is executed by software)
    SNAP_CONFIG=1


	SNAP_CONFIG=1 ./snap_intersect -m0 -s  (software naive way for intersection)
	SNAP_CONFIG=1 ./snap_intersect -m1 -s  (software hash method)
	SNAP_CONFIG=1 ./snap_intersect -m2 -s  (software sort method)
	"-s" is needed. 

## Other arguments please look in `./snap_intersect -h`

