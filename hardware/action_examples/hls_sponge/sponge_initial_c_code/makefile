# Benchmark Sponge

#16384
#32768
#65536
#131072
#262144
#524288
#1048576
#2097152
#4194304
#8388608
#16777216
CC=gcc
CPPFLAGS=-DNB_SLICES=65536 -DNB_ROUND=16777216 # Le vrai benchmark
#CPPFLAGS=-DNB_SLICES=32 -DNB_ROUND=1048576
#CPPFLAGS=-DNB_SLICES=8 -DNB_ROUND=2048
#CPPFLAGS=-DNB_SLICES=4 -DNB_ROUND=1024
#CPPFLAGS=-DNB_SLICES=32 -DNB_ROUND=16384
OPT=-O3 -mavx
FLAGS=$(OPT) $(CPPFLAGS)
FLAGS_TEST=$(OPT) -DTEST

all: sponge sponge_test

sponge: sponge.c keccak.c
	$(CC) $(FLAGS) sponge.c keccak.c -o sponge

sponge_test: sponge.c keccak.c
	$(CC) $(FLAGS_TEST) sponge.c keccak.c -o sponge_test

test: sponge_test
	time ./sponge_test 0 1
	time ./sponge_test 0 2
	time ./sponge_test 1 2
	time ./sponge_test 0 4
	time ./sponge_test 1 4
	time ./sponge_test 2 4
	time ./sponge_test 3 4

clean:
	rm -f *~ *.o sponge sponge_test
