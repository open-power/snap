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
  tp=0
  iter=0
}
{
  #Construct the tables. Index starts from 1
  if ($0 ~ "Testpoint") {
	  tp++
          iter=0
	  tp_name[tp] = $0
  }
  if ($0 ~ "snap_scatter_gather")	{iter++}
   
  if ($0 ~ "Action Stop")		{usec_table[tp][iter]=$3}
  if ($0 ~ "Software gathers")		{usec_sw[tp][iter]=$3}
}
END {
  i=1
  t=1
  error=0

  printf "---------------------- Process %s Testpoints (Each has %s logs) -------------------------\n", tp, iter
  printf "                       (time in usec)\n"
  while (t <= tp) {
	##############################
	i=1
	min = usec_table[t][1]
	max = usec_table[t][1]
	sum = 0;
	while (i <= iter) {
		if (usec_table[t][i] < min) {min=usec_table[t][i]}
		if (usec_table[t][i] > max) {max=usec_table[t][i]}
		sum = sum + usec_table[t][i]
		i++
	}
	average = sum/iter
	###########################
	i=1
	min_s = usec_sw[t][1]
	max_s = usec_sw[t][1]
	sum_s = 0;
	while (i <= iter) {
		if (usec_sw[t][i] < min_s) {min_s=usec_sw[t][i]}
		if (usec_sw[t][i] > max_s) {max_s=usec_sw[t][i]}
		sum_s = sum_s + usec_sw[t][i]
		i++
	}
	average_s = sum_s/iter
	###########################
	printf "%2s-%-40s:", t, tp_name[t]

	printf " SW : %-7s (min: %-5s max: %-5s);", average_s, min_s, max_s
	printf " HW : %-7s (min: %-5s max: %-5s)", average, min, max
	printf " Sum: %s\n", average_s + average
	t++
  }
		
}
