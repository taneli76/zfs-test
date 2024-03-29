#! /usr/bin/ksh -p
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
. $STF_SUITE/tests/functional/zvol/zvol_common.shlib

#
# DESCRIPTION:
# 	Verify a device cannot be dump and swap at the same time.
#
# STRATEGY:
# 1. Create a ZFS volume
# 2. Set it as swap device.
# 3. Verify dumpadm with this zvol will fail.
#

verify_runnable "global"

function cleanup
{
	if [[ -n "$LINUX" ]]; then
		$SWAP -s | $GREP $voldev > /dev/null 2>&1
	else
		$SWAP -l | $GREP $voldev > /dev/null 2>&1
	fi
	if (( $? == 0 )) ; then
		if [[ -n "$LINUX" ]]; then
			log_must swapoff $voldev
		else
			log_must $SWAP -d $voldev
		fi
	fi

	typeset dumpdev=$(get_dumpdevice)
	if [[ $dumpdev != $savedumpdev ]] ; then
		safe_dumpadm $savedumpdev
	fi
}

log_assert "Verify a device cannot be dump and swap at the same time."
log_onexit cleanup

voldev=$ZVOL_DEVDIR/$TESTPOOL/$TESTVOL
savedumpdev=$(get_dumpdevice)

# If device in swap list, it cannot be dump device
if [[ -n "$LINUX" ]]; then
	log_must mkswap $voldev
	log_must $SWAP $voldev
else
	log_must $SWAP -a $voldev
fi
log_mustnot $DUMPADM -d $voldev
if [[ -n "$LINUX" ]]; then
	log_must swapoff $voldev
else
	log_must $SWAP -d $voldev
fi

# If device has dedicated as dump device, it cannot add into swap list
safe_dumpadm $voldev
if [[ -n "$LINUX" ]]; then
	log_mustnot mkswap $voldev
	log_mustnot $SWAP $voldev
else
	log_mustnot $SWAP -a $voldev
fi

log_pass "A device cannot be dump and swap at the same time."
