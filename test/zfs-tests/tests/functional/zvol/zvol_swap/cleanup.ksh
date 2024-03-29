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
. $STF_SUITE/tests/functional/zvol/zvol_swap/zvol_swap.cfg

verify_runnable "global"

[[ -z "$LINUX" ]] && log_must $SWAPADD
for swapdev in $SAVESWAPDEVS
do
	if ! is_swap_inuse $swapdev ; then
		if [[ -n "$LINUX" ]]; then
			log_must mkswap $swapdev >/dev/null 2>&1
			log_must $SWAP $swapdev >/dev/null 2>&1
		else
			log_must $SWAP -a $swapdev >/dev/null 2>&1
		fi
	fi
done

voldev=$ZVOL_DEVDIR/$TESTPOOL/$TESTVOL
if is_swap_inuse $voldev ; then
	if [[ -n "$LINUX" ]]; then
		log_must swapoff $voldev
	else
		log_must $SWAP -d $voldev
	fi
fi

default_zvol_cleanup

log_pass
