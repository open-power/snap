#!/usr/bin/python

#
# Copyright 2017 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import re
import getopt, sys

def analyze_file(fname):
	seqs = []
	with open(fname, "r") as ins:
		lba_last = 0
		last_seq = 0
		for line in ins:
			m = re.search(r"LBA=(\d+)", line)
			if not m:
				continue
			lba = int(m.group(1))
			if lba == lba_last + 2:
				#print(">>> " + str(lba))
				last_seq += 1
			elif lba == lba_last - 2:
				#print("<<< " + str(lba))
				last_seq -= 1
			else:
				#print("    " + str(lba))
				seqs.append(last_seq)
				last_seq = 0
			lba_last = lba

	max_pos = max(seqs)
	min_neg = min(seqs)

	print("Largest positive sequence: " + str(max_pos))
	print("Largest negative sequence: " + str(min_neg))

	# define array of accumulated sizes
	count_seqs = [0] * (max_pos + 1 + abs(min_neg));
	for e in seqs:
		count_seqs[abs(min_neg) + e] += 1

	i = min_neg
	for e in count_seqs:
		print("[" + str(i) + "] " + str(e))
		i += 1

def usage():
	print("lbalog_analysis.py [-help] -i filename.log")

def main():
	try:
		opts, args = getopt.getopt(sys.argv[1:], "hi:", ["help", "input="])
	except getopt.GetoptError as err:
        # print help information and exit:
		print str(err)
		usage()
		sys.exit(2)

	# fname = None
	fname = "run_threads1_prefetch0_lbas.log"

	for o, a in opts:
		if o in ("-h", "--help"):
			usage()
			sys.exit()
		elif o in ("-i", "--input"):
			fname = a
		else:
			assert False, "unhandled option"

	analyze_file(fname)

if __name__ == "__main__":
	main()
