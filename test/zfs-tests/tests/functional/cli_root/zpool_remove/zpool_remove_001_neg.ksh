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
# Copyright (c) 2012 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/cli_root/zpool_remove/zpool_remove.cfg
. $TMPFILE

#
# DESCRIPTION:
# Verify that 'zpool can not remove device except inactive hot spares from pool'
#
# STRATEGY:
# 1. Create all kinds of pool (strip, mirror, raidz, hotspare)
# 2. Try to remove device from the pool
# 3. Verify that the remove failed.
#

typeset slice_part=s
[[ -n "$LINUX" ]] && slice_part=p

typeset disk=${DISK}
typeset vdev_devs="${disk}${slice_part}${SLICE0}"
typeset mirror_devs="${disk}${slice_part}${SLICE0} ${disk}${slice_part}${SLICE1}"
typeset raidz_devs=${mirror_devs}
typeset raidz1_devs=${mirror_devs}
typeset raidz2_devs="${mirror_devs} ${disk}${slice_part}${SLICE3}"
typeset spare_devs1="${disk}${slice_part}${SLICE0}"
typeset spare_devs2="${disk}${slice_part}${SLICE1}"

function check_remove
{
        typeset pool=$1
        typeset devs="$2"
        typeset dev

        for dev in $devs; do
                log_mustnot $ZPOOL remove $dev
        done

        destroy_pool -f $pool

}

function cleanup
{
	destroy_pool -f $TESTPOOL
}

set -A create_args "$vdev_devs" "mirror $mirror_devs"  \
		"raidz $raidz_devs" "raidz $raidz1_devs" \
		"raidz2 $raidz2_devs" \
		"$spare_devs1 spare $spare_devs2"

set -A verify_disks "$vdev_devs" "$mirror_devs" "$raidz_devs" \
		"$raidz1_devs" "$raidz2_devs" "$spare_devs1"


log_assert "Check zpool remove <pool> <device> can not remove " \
	"active device from pool"

log_onexit cleanup

typeset -i i=0
while [[ $i -lt ${#create_args[*]} ]]; do
	log_must $ZPOOL create $TESTPOOL ${create_args[i]}
	check_remove $TESTPOOL "${verify_disks[i]}"
	(( i = i + 1))
done

log_pass "'zpool remove <pool> <device> fail as expected .'"
