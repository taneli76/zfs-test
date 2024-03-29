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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2012 by Delphix. All rights reserved.
#

#
# Copyright (c) 2013 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/xattr/xattr_common.kshlib

#
# DESCRIPTION:
# xattr file sizes count towards normal disk usage
#
# STRATEGY:
#	1. Create a file, and check pool and filesystem usage
#       2. Create a 200mb xattr in that file
#	3. Check pool and filesystem usage, to ensure it reflects the size
#	   of the xattr
#

function cleanup {
	log_must $RM $TESTDIR/myfile.$$
}

function get_pool_size {
	poolname=$1
	psize=$($ZPOOL list -H -o allocated $poolname)
	if [[ $psize == *[mM] ]]
	then
		returnvalue=$($ECHO $psize | $SED -e 's/m//g' -e 's/M//g')
		returnvalue=$((returnvalue * 1024))
	else
		returnvalue=$($ECHO $psize | $SED -e 's/k//g' -e 's/K//g')
	fi
	echo $returnvalue
}

log_assert "xattr file sizes count towards normal disk usage"
log_onexit cleanup

log_must $TOUCH $TESTDIR/myfile.$$

POOL_SIZE=0
NEW_POOL_SIZE=0

if is_global_zone
then
	# get pool and filesystem sizes. Since we're starting with an empty
	# pool, the usage should be small - a few k.
	POOL_SIZE=$(get_pool_size $TESTPOOL)
fi

FS_SIZE=$($ZFS get -p -H -o value used $TESTPOOL/$TESTFS)

log_must $RUNAT $TESTDIR/myfile.$$ $MKFILE -s 200m xattr

#Make sure the newly created file is counted into zpool usage
log_must $SYNC

# now check to see if our pool disk usage has increased
if is_global_zone
then
	NEW_POOL_SIZE=$(get_pool_size $TESTPOOL)
	(($NEW_POOL_SIZE <= $POOL_SIZE)) && \
	    log_fail "The new pool size $NEW_POOL_SIZE was less \
            than or equal to the old pool size $POOL_SIZE."

fi

# also make sure our filesystem usage has increased
NEW_FS_SIZE=$($ZFS get -p -H -o value used $TESTPOOL/$TESTFS)
(($NEW_FS_SIZE <= $FS_SIZE)) && \
    log_fail "The new filesystem size $NEW_FS_SIZE was less \
    than or equal to the old filesystem size $FS_SIZE."

log_pass "xattr file sizes count towards normal disk usage"
