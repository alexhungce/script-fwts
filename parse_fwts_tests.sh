#!/bin/bash
# Copyright (C) 2016-2021 Canonical
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

if ! which fwts > /dev/null ; then
	echo "fwts is not installed..."
	exit 1
fi

fwts --show-tests | awk '{
	if ($0 ~ /:/) {
		print "=== " substr($0, 0, length($0)-1) " ==="
	} else if (length($0) == 0) {
		# do nothing
	} else {
		printf "||[[FirmwareTestSuite/Reference/" $1 "|"$1 "]]\t|| " ;
		for(i = 2; i <= NF; ++i)
			printf $i " "
		print "||"
	}
}'
