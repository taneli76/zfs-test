#!/bin/ksh -p
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
. $STF_SUITE/tests/functional/snapshot/snapshot.cfg

#
# DESCRIPTION:
#	Verify renamed snapshots via mv can be destroyed
#
# STRATEGY:
#	1. Create snapshot
#	2. Rename the snapshot via mv command
#	2. Verify destroying the renamed snapshot via 'zfs destroy' succeeds
#

verify_runnable "both"

function cleanup
{
	destroy_dataset -Rf $SNAPFS
	destroy_dataset -Rf $TESTPOOL/$TESTFS@snap_a
	destroy_dataset -Rf $TESTPOOL/$TESTCLONE@snap_a

	destroy_dataset $TESTPOOL/$TESTCLONE
	destroy_dataset $TESTPOOL/$TESTFS

	log_must $ZFS create $TESTPOOL/$TESTFS
	log_must $ZFS set mountpoint=$TESTDIR $TESTPOOL/$TESTFS
}

log_assert "Verify renamed snapshots via mv can be destroyed."
log_onexit cleanup

# scenario 1

log_must $ZFS snapshot $SNAPFS
log_must $MV $TESTDIR/$SNAPROOT/$TESTSNAP $TESTDIR/$SNAPROOT/snap_a

datasetexists $TESTPOOL/$TESTFS@snap_a || \
	log_fail "rename snapshot via mv in .zfs/snapshot fails."
destroy_dataset $TESTPOOL/$TESTFS@snap_a

# scenario 2

log_must $ZFS snapshot $SNAPFS
log_must $ZFS clone $SNAPFS $TESTPOOL/$TESTCLONE
log_must $MV $TESTDIR/$SNAPROOT/$TESTSNAP $TESTDIR/$SNAPROOT/snap_a

datasetexists $TESTPOOL/$TESTFS@snap_a || \
        log_fail "rename snapshot via mv in .zfs/snapshot fails."
log_must $ZFS promote $TESTPOOL/$TESTCLONE
# promote back to $TESTPOOL/$TESTFS for scenario 3
log_must $ZFS promote $TESTPOOL/$TESTFS
destroy_dataset $TESTPOOL/$TESTCLONE
destroy_dataset $TESTPOOL/$TESTFS@snap_a

# scenario 3

log_must $ZFS snapshot $SNAPFS
log_must $ZFS clone $SNAPFS $TESTPOOL/$TESTCLONE
log_must $ZFS rename $SNAPFS $TESTPOOL/$TESTFS@snap_a
log_must $ZFS promote $TESTPOOL/$TESTCLONE
destroy_dataset $TESTPOOL/$TESTFS
destroy_dataset $TESTPOOL/$TESTCLONE@snap_a

log_pass "Verify renamed snapshots via mv can be destroyed."
