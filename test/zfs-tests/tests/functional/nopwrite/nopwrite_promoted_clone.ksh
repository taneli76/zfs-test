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
# Verify that nopwrite still works for a dataset that becomes a clone via
# promotion.
#
# Strategy:
# 1. Create a clone suitable for nopwrite.
# 2. Disable compression and checksum on the clone, and promote it.
# 3. Overwrite the file in the clone (former origin fs) and verify it
# consumes no additional space.
#

verify_runnable "global"
origin="$TESTPOOL/$TESTFS"
log_onexit cleanup

function cleanup
{
	destroy_dataset -R $TESTPOOL/clone
	log_must $ZFS create -o mountpoint=$TESTDIR $origin
}

log_assert "nopwrite works on a dataset that becomes a clone via promotion."

log_must $ZFS set compress=on $origin
log_must $ZFS set checksum=sha256 $origin
$DD if=/dev/urandom of=$TESTDIR/file bs=1024k count=$MEGS conv=notrunc \
    >/dev/null 2>&1 || log_fail "dd into $TESTDIR/file failed."
$ZFS snapshot $origin@a || log_fail "zfs snap failed"
log_must $ZFS clone $origin@a $TESTPOOL/clone
log_must $ZFS set compress=off $TESTPOOL/clone
log_must $ZFS set checksum=off $TESTPOOL/clone
log_must $ZFS promote $TESTPOOL/clone
$DD if=/$TESTPOOL/clone/file of=/$TESTDIR/file bs=1024k count=$MEGS \
    conv=notrunc >/dev/null 2>&1 || log_fail "dd failed."
log_must verify_nopwrite $TESTPOOL/clone $TESTPOOL/clone@a $origin

log_pass "nopwrite works on a dataset that becomes a clone via promotion."
