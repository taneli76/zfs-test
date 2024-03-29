#!/usr/bin/ksh -p
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2013 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/replacement/replacement.cfg

#
# DESCRIPTION:
# 	Attaching disks during I/O should pass for supported pools.
#
# STRATEGY:
#	1. Create multidisk pools (stripe/mirror/raidz) and
#	   start some random I/O
#	2. Attach a disk to the pool.
#	3. Verify the integrity of the file system and the resilvering.
#

verify_runnable "global"

function cleanup
{
	if [[ -n "$child_pids" ]]; then
		for wait_pid in $child_pids
		do
		        $KILL $wait_pid
		done
	fi

	destroy_pool -f $TESTPOOL1

	[[ -e $TESTDIR ]] && log_must $RM -rf $TESTDIR/*
}

log_assert "Replacing a disk during I/O completes."

options=""
options_display="default options"

log_onexit cleanup

[[ -n "$HOLES_FILESIZE" ]] && options=" $options -f $HOLES_FILESIZE "

[[ -n "$HOLES_BLKSIZE" ]] && options="$options -b $HOLES_BLKSIZE "

[[ -n "$HOLES_COUNT" ]] && options="$options -c $HOLES_COUNT "

[[ -n "$HOLES_SEED" ]] && options="$options -s $HOLES_SEED "

[[ -n "$HOLES_FILEOFFSET" ]] && options="$options -o $HOLES_FILEOFFSET "

options="$options -r "

[[ -n "$options" ]] && options_display=$options

child_pids=""

function attach_test
{
	typeset -i iters=2
	typeset -i index=0
	typeset opt=$1
	typeset disk1=$2
	typeset disk2=$3

	typeset i=0
	while [[ $i -lt $iters ]]; do
		log_note "Invoking $FILE_TRUNC with: $options_display"
		$FILE_TRUNC $options $TESTDIR/$TESTFILE.$i &
		typeset pid=$!

		$SLEEP 1
		if ! $PS -p $pid > /dev/null 2>&1; then
			log_fail "$FILE_TRUNC $options $TESTDIR/$TESTFILE.$i"
		fi

		child_pids="$child_pids $pid"
		((i = i + 1))
	done

	log_must $ZPOOL attach $opt $TESTPOOL1 $disk1 $disk2

	$SLEEP 10

	for wait_pid in $child_pids
	do
		$KILL $wait_pid
	done
	child_pids=""

        log_must $ZPOOL export $TESTPOOL1
        log_must $ZPOOL import -d $TESTDIR $TESTPOOL1
        log_must $ZFS umount $TESTPOOL1/$TESTFS1
        log_must $ZDB -cdui $TESTPOOL1/$TESTFS1
        log_must $ZFS mount $TESTPOOL1/$TESTFS1

}

specials_list=""
i=0
while [[ $i != 2 ]]; do
	$MKFILE -s 100m $TESTDIR/$TESTFILE1.$i
	specials_list="$specials_list $TESTDIR/$TESTFILE1.$i"

	((i = i + 1))
done

#
# Create a replacement disk special file.
#
$MKFILE -s 100m $TESTDIR/$REPLACEFILE

for op in "" "-f"; do
	create_pool $TESTPOOL1 mirror $specials_list
	log_must $ZFS create $TESTPOOL1/$TESTFS1
	log_must $ZFS set mountpoint=$TESTDIR1 $TESTPOOL1/$TESTFS1

	attach_test "$opt" $TESTDIR/$TESTFILE1.1 $TESTDIR/$REPLACEFILE

	$ZPOOL iostat -v $TESTPOOL1 | grep "$TESTDIR/$REPLACEFILE"
	if [[ $? -ne 0 ]]; then
		log_fail "$REPLACEFILE is not present."
	fi

	destroy_pool -f $TESTPOOL1
done

log_note "Verify 'zpool attach' fails with non-mirrors."

for type in "" "raidz" "raidz1"; do
	for op in "" "-f"; do
		create_pool $TESTPOOL1 $type $specials_list
		log_must $ZFS create $TESTPOOL1/$TESTFS1
		log_must $ZFS set mountpoint=$TESTDIR1 $TESTPOOL1/$TESTFS1

		log_mustnot $ZPOOL attach "$opt" $TESTDIR/$TESTFILE1.1 \
		    $TESTDIR/$REPLACEFILE

		$ZPOOL iostat -v $TESTPOOL1 | grep "$TESTDIR/$REPLACEFILE"
		if [[ $? -eq 0 ]]; then
		        log_fail "$REPLACEFILE should not be present."
		fi

		destroy_pool -f $TESTPOOL1
	done
done

log_pass
