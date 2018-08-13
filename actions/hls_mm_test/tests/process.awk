#! /usr/bin/awk -f
#
#    It takes 2894 usec for Allocate and prepare buffers
#    It takes 790 usec for Open the card
#    It takes 14 usec for Attach action
#    It takes 1 usec for SNAP prepare job_t structure
#    It takes 4 usec for Use MMIO to transfer the parameters
#    It takes 1 usec for Use MMIO to kick off "Action Start"
#    It takes 349 usec for Use MMIO to poll "Action Stop" bit
#====================  All job finished ==================
#    It takes 3 usec for Detach action
#    It takes 92 usec for Close the card
#    It takes 18 usec for Free all buffers

# $0: the whole current line
# $1: the first segement
# FS: separate character

BEGIN {
  FS=" "
}
{
  if ($0 ~ "snap_mm_test")	{iter++}
   
  if ($0 ~ "Allocate")		{usec_table[1][iter]=$3}
  if ($0 ~ "Open the card")	{usec_table[2][iter]=$3}
  if ($0 ~ "Attach")		{usec_table[3][iter]=$3}
  if ($0 ~ "prepare")		{usec_table[4][iter]=$3}
  if ($0 ~ "parameters")	{usec_table[5][iter]=$3}
  if ($0 ~ "Action Start")	{usec_table[6][iter]=$3}
  if ($0 ~ "Action Stop")	{usec_table[7][iter]=$3}
  if ($0 ~ "Detach")		{usec_table[8][iter]=$3}
  if ($0 ~ "Close")		{usec_table[9][iter]=$3}
  if ($0 ~ "Free")		{usec_table[10][iter]=$3}
}
END {
  i=1
  t=1
  error=0

  printf "---------------------- Process %s logs ----------------------------\n", iter
  printf "                       (time in usec)\n", iter
  while (t <= 10) {
	i=1
	min = usec_table[t][1];
	max = usec_table[t][1];
	sum = 0;
	while (i <= iter) {
		if (usec_table[t][i] < min) {min=usec_table[t][i]}
		if (usec_table[t][i] > max) {max=usec_table[t][i]}
		sum = sum + usec_table[t][i]
		i++
	}
	average = sum/iter
	
	if (t == 1) {printf "%20s", "Allocate"}
	if (t == 2) {printf "%20s", "Open the card"}
	if (t == 3) {printf "%20s", "Attach"}
	if (t == 4) {printf "%20s", "SNAP prepare"}
	if (t == 5) {printf "%20s", "MMIO parameters"}
	if (t == 6) {printf "%20s", "MMIO Action Start"}
	if (t == 7) {printf "%20s", "*** MMIO Action Stop"}
	if (t == 8) {printf "%20s", "Detach"}
	if (t == 9) {printf "%20s", "Close"}
	if (t == 10) {printf "%20s", "Free"}
	printf " average: %-8s (min: %-8s max: %-8s)\n", average, min, max
	t++
  }
		
}
