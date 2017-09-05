#! /usr/bin/awk -f
BEGIN {
  FS=" "
}
{
#  print $1
  if ($1 ~ "gen_input_table") {
         iter++
         table_num[iter]=$2
         }
  if ($0 ~ "HW steps") {
      hw=1
      sw=0
  }
  if ($0 ~ "SW steps") {
      hw=0
      sw=1
  }
   
  if (hw == 1 && $0 ~ "Step 1 took") {step1_hw[iter]=$4}
  if (sw == 1 && $0 ~ "Step 1 took") {step1_sw[iter]=$4}
  if ($0 ~ "Step 2 took") {step2[iter]=$4}
  if ($0 ~ "Step 3 took") {step3[iter]=$4}
  if ($0 ~ "Step 4 took") {step4[iter]=$4}
  if ($0 ~ "Step 5 took") {step5[iter]=$4}
  if ($0 ~ "HW: result_num") {hw_num[iter]=$4}
  if ($0 ~ "SW: result_num") {sw_num[iter]=$4}
}
END {
  i=1
  error=0
  printf "%-2s%8s|%8s%8s|%8s%8s\n","#","TableNum", "HW func", "SW func", "HW mcpy", "SW mcpy"
  printf "%-2s%8s|%8s%8s|%8s%8s\n","","", "Step3", "Step4", "Step5", "Step2"
  while (i <= iter) {
    printf "%-2s%8s|%8s%8s|%8s%8s\n",i, table_num[i],step3[i], step4[i], step5[i], step2[i]
   
    if(hw_num[i] != sw_num[i]) {
      print "Result num MISCOMPARE!"
      print "ERROR and exit."
      error=1
      exit 1
    }
    i++
  }
}
