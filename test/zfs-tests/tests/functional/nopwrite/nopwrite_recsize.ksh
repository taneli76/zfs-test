#!/usr/bin/ksh

#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#

#
# Copyright (c) 2012 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/nopwrite/nopwrite.shlib

#
# Description:
# Verify that nopwrite works regardless of recsize property setting.
#
# Strategy:
# 1. Create an origin fs that's suitable to make nopwrite clones.
# 2. For each possible recsize, create a clone that inherits the compress and
# checksum, and verify overwriting the origin file consumes no new space.
#

verify_runnable "global"
origin="$TESTPOOL/$TESTFS"
log_onexit cleanup

function cleanup
{
	destroy_dataset -R $origin
	log_must $ZFS create -o mountpoint=$TESTDIR $origin
}

log_assert "nopwrite updates file metadata correctly"

log_must $ZFS set compress=on $origin
log_must $ZFS set checksum=sha256 $origin
$DD if=/dev/urandom of=$TESTDIR/file bs=1024k count=$MEGS conv=notrunc \
    >/dev/null 2>&1 || log_fail "dd into $TESTDIR/file failed."
$ZFS snapshot $origin@a || log_fail "zfs snap failed"
log_must $ZFS clone $origin@a $origin/clone

for rs in 512 1024 2048 4096 8192 16384 32768 65536 131072 ; do
	log_must $ZFS set recsize=$rs $origin/clone
	$DD if=/$TESTDIR/file of=/$TESTDIR/clone/file bs=1024k count=$MEGS \
	    conv=notrunc >/tmp/null 2>&1 || log_fail "dd failed."
	log_must verify_nopwrite $origin $origin@a $origin/clone
done

log_pass "nopwrite updates file metadata correctly"
