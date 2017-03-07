/*
 * Sponge: hash sha-3 (keccak)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "keccak.h"
#ifdef MPI
#include "mpi.h"
#endif

#define HASH_SIZE 64
#define RESULT_SIZE 8

#ifdef NO_SYNTH /* TEST */
#  define NB_SLICES 4
#  define NB_ROUND 1<<10
#else
#  ifndef NB_SLICES
#    define NB_SLICES 65536 /* 4 */	//65536--for first synthesis
#  endif
#  ifndef NB_ROUND
#    define NB_ROUND 1<<24 /* 10 */	//24--for first synthesis
#  endif
#endif

uint64_t sponge (const uint64_t rank) {
  uint64_t magic[8] = {0x0123456789abcdeful,0x13579bdf02468aceul,0xfdecba9876543210ul,0xeca86420fdb97531ul,
                       0x571e30cf4b29a86dul,0xd48f0c376e1b29a5ul,0xc5301e9f6b2ad748ul,0x3894d02e5ba71c6ful};
  uint64_t odd[8],even[8],result;

  int i,j;

  for(i=0;i<RESULT_SIZE;i++) {
    even[i] = magic[i] + rank;
  }

  //keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
  keccak((uint64_t*)even,HASH_SIZE,(uint64_t*)odd,HASH_SIZE);
  for(i=0;i<NB_ROUND;i++) {
    for(j=0;j<4;j++) {
      odd[2*j] ^= ROTL64( even[2*j] , 4*j+1);
      odd[2*j+1] = ROTL64( even[2*j+1] + odd[2*j+1], 4*j+3);
    }
    //keccak((uint8_t*)odd,HASH_SIZE,(uint8_t*)even,HASH_SIZE);
    keccak((uint64_t*)odd,HASH_SIZE,(uint64_t*)even,HASH_SIZE);
    for(j=0;j<4;j++) {
      even[2*j] += ROTL64( odd[2*j] , 4*j+5);
      even[2*j+1] = ROTL64( even[2*j+1] ^ odd[2*j+1], 4*j+7);
    }
    //keccak((uint8_t*)even,HASH_SIZE,(uint8_t*)odd,HASH_SIZE);
    keccak((uint64_t*)even,HASH_SIZE,(uint64_t*)odd,HASH_SIZE);
  }
  result=0;
  for(i=0;i<RESULT_SIZE;i++) {
    result += (even[i] ^ odd[i]);
  }
  return result;
}

#ifdef NO_SYNTH
int main(void)
{

	  uint64_t slice;
	  //uint32_t pe,nb_pe;
      uint64_t checksum=0;
	  short i, rc=0;


      typedef struct {
    	  uint32_t  pe;
    	  uint32_t  nb_pe;
    	  uint64_t checksum;
      } arguments_t;


      static arguments_t sequence[] = {
    		  { /*pe =*/  0, /*nb_pe =*/  1, /*expected checksum =*/ 0x948dd5b0109342d4 },
			  { /*pe =*/  0, /*nb_pe =*/  2, /*expected checksum =*/ 0x0bca19b17df64085 },
			  { /*pe =*/  1, /*nb_pe =*/  2, /*expected checksum =*/ 0x9f47cc016d650251 },
			  { /*pe =*/  0, /*nb_pe =*/  4, /*expected checksum =*/ 0x7f13a4a377a2c4fe },
			  { /*pe =*/  1, /*nb_pe =*/  4, /*expected checksum =*/ 0xee0710b96b0748fb },
			  { /*pe =*/  2, /*nb_pe =*/  4, /*expected checksum =*/ 0x74d9bd120a54847b },
			  { /*pe =*/  3, /*nb_pe =*/  4, /*expected checksum =*/ 0x7140dcb806624aaa }
      };


      for(i=0; i < 7; i++) {
    	  checksum = 0;
    	  for(slice=0;slice<NB_SLICES;slice++) {
    		  if(sequence[i].pe == (slice % sequence[i].nb_pe)) checksum ^= sponge(slice);
    	  }
    	  printf("pe=%d - nb_pe=%d - processed checksum=%016llx ",
    			  sequence[i].pe,
    			  sequence[i].nb_pe,
				  (unsigned long long) checksum);
    	  if (sequence[i].checksum == checksum) {
        	  printf(" ==> CORRECT \n");
        	  rc |= 0;
    	  }
    	  else {
    		  printf(" ==> ERROR : expected checksum=%016llx \n",
    				  (unsigned long long) sequence[i].checksum);
    		  rc |= 1;
    	  }
      }
      if (rc != 0) printf("\n\t Checksums are given with use of -DTEST flag. Please check you have set it!\n\n");
      return rc;
}
#endif // end of NO_SYNTH flag

#ifdef C_TEST
int main(int argc,char **argv) {
  uint32_t slice,pe,nb_pe;
  uint64_t checksum=0;
#ifdef MPI
  uint64_t gchecksum=0;
#endif

#ifdef MPI
  MPI_Init(&argc,&argv);
  MPI_Comm_size(MPI_COMM_WORLD,&nb_pe);
  MPI_Comm_rank(MPI_COMM_WORLD,&pe);
#else
  if(argc!=3) {
    printf("Usage: %s pe nb_pe\n",argv[0]);
    return 1;
  }
  pe = (uint32_t) atol(argv[1]);
  nb_pe = (uint32_t) atol(argv[2]);
#endif

  for(slice=0;slice<NB_SLICES;slice++) {
    if(pe == (slice % nb_pe)) checksum ^= sponge(slice);
  }
#ifdef MPI
  // Calcul du checksum global
  MPI_Allreduce(&checksum,&gchecksum,1,MPI_UNSIGNED_LONG_LONG,MPI_BXOR,MPI_COMM_WORLD);
  if(pe==0) 
    printf("checksum=%016llx\n",(unsigned long long) gchecksum);
  MPI_Finalize();
#else
  printf("checksum=%016llx\n",(unsigned long long) checksum);
#endif
  return 0;
}
#endif // end of C_TEST flag


