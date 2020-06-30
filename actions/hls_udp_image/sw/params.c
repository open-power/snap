/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
#include "params.h" 


void usage(const char *prog)
{
	printf("Usage: %s [-h] \n"
	"  -C, --card <cardno>       can be (0...3)\n"
        "\n"
        "Useful parameters (to be placed before the command):\n"
        "----------------------------------------------------\n"
        "SNAP_TRACE=0x0   no debug trace  (default mode)\n"
        "SNAP_TRACE=0xF   full debug trace\n"
        "SNAP_CONFIG=FPGA hardware execution   (default mode)\n"
        "SNAP_CONFIG=CPU  software execution\n"
        "\n"
        "Example on a real card:\n"
        "-----------------------\n"
        "cd ~/snap && export ACTION_ROOT=~/snap/actions/hls_udp_image\n"
        "source snap_path.sh\n"
        "echo locate the slot number used by your card\n"
        "snap_find_card -v -AALL\n"
        "echo discover the actions in card in slot 0\n"
        "snap_maint -vv -C0\n"
        "\n"
        "echo Run the application + hardware action on FPGA\n"
        "snap_udp_image -c 0\n"
        "...\n"	, prog);
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
			{ "card",	 required_argument, NULL, 'c' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "c:h",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'c':
			parms.card_no = strtol(optarg, (char **)NULL, 0);
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


