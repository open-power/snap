#!/usr/bin/perl -w

print << 'EOF';
/*
 * Copyright 2017 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __SNAP_ACTIONS_H__
#define __SNAP_ACTIONS_H__

#include <stdint.h>

struct actions_tab {
        const char *vendor;
        uint32_t dev1;
        uint32_t dev2;
        const char *description;
};

static const struct actions_tab snap_actions[] = {
EOF

sub trim($) {
  my $l = shift;
  $l =~ s/^\s+|\s+$//g;
  return $l;
}

sub hexlify($) {
  my $n = shift;
  $n =~ s/\.//g;
  return $n;
}

my $num = 0;

# Processing code goes here
LINE: while (<>) {
  chomp();
  @data = split(/\|/, $_);

  next LINE if (scalar(@data) != 4);

  $num += 1;
  next LINE if ($num <= 2);

  ($vendor, $dev1, $dev2, $descr) = map {trim($_)} @data;
  printf("  { \"%s\", 0x%s, 0x%s, \"%s\" },\n",
	 $vendor, hexlify($dev1), hexlify($dev2), $descr);
}

print << 'EOF';
};

#endif  /* __SNAP_ACTIONS_H__ */
EOF
