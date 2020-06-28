/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
#include "params.h" 


void usage(const char *prog)
{
	printf("Usage: %s [-h] \n"
	"  -i, --input <file.bin>    input file.\n"
	"  -o, --output <file.bin>   output file.\n", prog);
}

/* main program of the application for the hls_image_filter example        */
/* This application will always be run on CPU and will call either       */
/* a software action (CPU executed) or a hardware action (FPGA executed) */
void  readParams(int argc, char *argv[])
{
	int ch;

	// collecting the command line arguments
	//const char *default_output = "test.bmp";
	
	//parms.output = default_output;
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "input",	 required_argument, NULL, 'i' },
			{ "output",	 required_argument, NULL, 'o' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "i:o::h",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'i':
			parms.input = optarg;
			break;
		case 'o':
			parms.output = optarg;
			break;
			/* input data */
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}
	if (argc == 1) {       // to provide help when program is called without argument
	  usage(argv[0]);
	  exit(EXIT_FAILURE);
	}
	
	//return(&parms);
		
}


