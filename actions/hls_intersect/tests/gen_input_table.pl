#!/usr/bin/perl


$argc = scalar(@ARGV);


# Generate uniq integers [min, max) 
if ($argc == 6)
{
	print "Get input @ARGV\n";
	$num[0] = $ARGV[0];
	$min[0] = $ARGV[1];
	$max[0] = $ARGV[2];
	$num[1] = $ARGV[3];
	$min[1] = $ARGV[4];
	$max[1] = $ARGV[5];
}
else
{
	$num[0] = 20;
	$min[0] = 0;
	$max[0] = 20;
	
	$num[1] = 30;
	$min[1] = 10;
	$max[1] = 40;
}


open (FILE1, ">table1.txt" ) || die "cannot open table1 file to write";
open (FILE2, ">table2.txt" ) || die "cannot open table2 file to write";

for ($tab = 0; $tab < 2; $tab = $tab +1)
{
	%hash = ();
	$i = 0;
	if( ($max[$tab] - $min[$tab]) < $num[$tab])
	{
		print "Error: cannot generated unique numbers for table $tab.\n";
		exit(-1);
	}
	while ($i < $num[$tab])
	{
		$temp = int(rand($max[$tab]-$min[$tab])) + $min[$tab];

		while (exists $hash{$temp})
		{
			# rand new.
			$temp = int(rand($max[$tab]-$min[$tab])) + $min[$tab];
		}

		$hash{$temp} = 1;
		

		$str = sprintf("%63d", $temp);



		
		print FILE1 $str."\n" if ($tab == 0);
		print FILE2 $str."\n" if ($tab == 1);

		$i = $i + 1;
	}
	print "Done\n";

}


close (FILE1);
close (FILE2);
