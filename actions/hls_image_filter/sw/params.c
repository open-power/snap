/**
 * @brief	prints valid command line options
 *
 * @param prog	current program's name
 */
#include "params.h" 

static const char *version = "01";

void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	"  -C, --card <cardno>       can be (0...3)\n"
	"  -i, --input <file.bin>    input file.\n"
	"  -o, --output <file.bin>   output file.\n"
	"  -A, --type-in <CARD_DRAM, HOST_DRAM, ...>.\n"
	"  -a, --addr-in <addr>      address e.g. in CARD_RAM.\n"
	"  -D, --type-out <CARD_DRAM,HOST_DRAM, ...>.\n"
	"  -d, --addr-out <addr>     address e.g. in CARD_RAM.\n"
	"  -t, --timeout             timeout in sec to wait for done.\n"
	"  -X, --verify              verify result if possible\n"
	"  -N, --no-irq              disable Interrupts\n"
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
        "cd ~/snap && export ACTION_ROOT=~/snap/actions/hls_image_filter\n"
        "source snap_path.sh\n"
        "echo locate the slot number used by your card\n"
        "snap_find_card -v -AALL\n"
        "echo discover the actions in card in slot 0\n"
        "snap_maint -vv -C0\n"
        "\n"
	"echo Run the application + hardware action on FPGA\n"
	"snap_image_filter -i ./actions/hls_image_filter/sw/tiger_small.bmp -o ./actions/hls_image_filter/sw/tiger_out.bmp\n"
	"...\n"
	"echo Run the application + software action on CPU\n"
	"\n"
        "Example for a simulation\n"
        "------------------------\n"
        "snap_maint -vv\n"
        "\n"
        "echo clean possible temporary old files \n"
	"rm tigre_small_sim.bmp\n"
	"\n"
	"echo Run the application + hardware action on the FPGA emulated on CPU\n"
	"snap_image_filter -i ../../../../actions/hls_image_filter/sw/tiger_small.bmp -o tiger_small_sim.bmp\n"
	"\n"
	"echo Run the application + software action on with trace ON\n"
	"SNAP_TRACE=0xF snap_image_filter -i ../../../../actions/hls_image_filter/sw/tigre_small.bmp -o tigre_small_sim.bmp\n"
	"\n",
        prog);
}

/* main program of the application for the hls_image_filter example        */
/* This application will always be run on CPU and will call either       */
/* a software action (CPU executed) or a hardware action (FPGA executed) */
STRparam* readParams(int argc, char *argv[])
{
	int ch;
	const char *space = "CARD_RAM";

	// collecting the command line arguments
	//const char *default_output = "test.bmp";
	
	//parms.output = default_output;
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "output",	 required_argument, NULL, 'o' },
			{ "src-type",	 required_argument, NULL, 'A' },
			{ "src-addr",	 required_argument, NULL, 'a' },
			{ "dst-type",	 required_argument, NULL, 'D' },
			{ "dst-addr",	 required_argument, NULL, 'd' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "verify",	 no_argument,	    NULL, 'X' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "C:i:o:A:a:D:d:s:t:XNVvh",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'C':
			parms.card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'i':
			parms.input = optarg;
			break;
		case 'o':
			parms.output = optarg;
			break;
			/* input data */
		case 'A':
			space = optarg;
			if (strcmp(space, "CARD_DRAM") == 0)
				parms.type_in = SNAP_ADDRTYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				parms.type_in = SNAP_ADDRTYPE_HOST_DRAM;
			else {
				usage(argv[0]);
				exit(EXIT_FAILURE);
			}
			break;
		case 'a':
			parms.addr_in = strtol(optarg, (char **)NULL, 0);
			break;
			/* output data */
		case 'D':
			space = optarg;
			if (strcmp(space, "CARD_DRAM") == 0)
				parms.type_out = SNAP_ADDRTYPE_CARD_DRAM;
			else if (strcmp(space, "HOST_DRAM") == 0)
				parms.type_out = SNAP_ADDRTYPE_HOST_DRAM;
			else {
				usage(argv[0]);
				exit(EXIT_FAILURE);
			}
			break;
		case 'd':
			parms.addr_out = strtol(optarg, (char **)NULL, 0);
			break;
                case 't':
                        parms.timeout = strtol(optarg, (char **)NULL, 0);
                        break;		
                case 'X':
			parms.verify++;
			break;
                case 'N':
                        parms.action_irq = 0;
                        break;
			/* service */
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			parms.verbose_flag = 1;
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
	
	return(&parms);
		
}


