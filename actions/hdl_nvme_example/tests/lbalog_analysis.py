#!/usr/bin/python
import re

def main():
	seqs = []
	with open("run_threads1_prefetch0_lbas.log", "r") as ins:
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

if __name__ == "__main__":
	main()
