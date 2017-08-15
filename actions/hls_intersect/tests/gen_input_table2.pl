#!/usr/bin/perl


$argc = scalar(@ARGV);


# Generate uniq integers [min, max) 
if ($argc == 3)
{
	$num[0] = $ARGV[0];
	$num[1] = $ARGV[1];
	$common_percentage = $ARGV[2]; #0-100
}
else
{
	$num[0] = 100;
	$num[1] = 100;
	$common_percentage = 50;
}


open (FILE1, ">table1.txt" ) || die "cannot open table1 file to write";
open (FILE2, ">table2.txt" ) || die "cannot open table2 file to write";

print "Table1: $num[0], Table2: $num[1], common percentage: $common_percentage%\n";
$i = 0;
$min_num = $num[0] > $num[1]? $num[1] : $num[0];
$maxLength = 63;
@dataSource = (0..9, 'a'..'z', 'A'..'Z');
while ($i < $min_num)
{
	$str1 = join '', map { $dataSource[int rand @dataSource]} 0..($maxLength-1);
	$str2 = join '', map { $dataSource[int rand @dataSource]} 0..($maxLength-1);
	
	print FILE1 $str1."\n";

	if ((int rand 100) < $common_percentage)
	{   
		#take the same as FILE1
		print FILE2 $str1."\n";
	}
	else
	{  
		#take a different random one.
		print FILE2 $str2."\n";
	}
	$i = $i + 1;
}

if ($min_num != $num[0])
{
	while ($i < $num[0])
	{
		$str1 = join '', map { $dataSource[int rand @dataSource]} 0..($maxLength-1);
		print FILE1 $str1."\n";
		$i = $i + 1;
	}
}
elsif ($min_num != $num[1])
{
	while ($i < $num[1])
	{
		$str2 = join '', map { $dataSource[int rand @dataSource]} 0..($maxLength-1);
		print FILE2 $str2."\n";
		$i = $i + 1;
	}
}


print "Done\n";



close (FILE1);
close (FILE2);
