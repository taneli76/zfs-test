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
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2013 by Delphix. All rights reserved.
#

. $STF_SUITE/tests/functional/rsend/rsend.kshlib

verify_runnable "both"

#
# Check if the system support 'send -R'
#
$ZFS send 2>&1 | $GREP "\[-[a-zA-Z]*R[a-zA-Z]*\]" >/dev/null 2>&1
if (($? != 0)); then
	log_unsupported
fi

if is_global_zone ; then
	destroy_pool -f $POOL
	destroy_pool -f $POOL2
else
	cleanup_pool $POOL
	cleanup_pool $POOL2
fi
log_must $RM -rf $BACKDIR $TESTDIR

log_pass
