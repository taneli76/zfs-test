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
# Copyright (c) 2012 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/cli_root/zpool_create/zpool_create.shlib
. $TMPFILE

#
# DESCRIPTION:
# 'zpool create [-R root][-m mountpoint] <pool> <vdev> ...' can create an
#  alternate root pool or a new pool mounted at the specified mountpoint.
#
# STRATEGY:
# 1. Create a pool with '-m' option
# 2. Verify the pool is mounted at the specified mountpoint
#

verify_runnable "global"

function cleanup
{
	destroy_pool $TESTPOOL
	for dir in $TESTDIR $TESTDIR1; do
		[[ -d $dir ]] && $RM -rf $dir
	done
}

log_assert "'zpool create [-R root][-m mountpoint] <pool> <vdev> ...' can create" \
	"an alternate pool or a new pool mounted at the specified mountpoint."
log_onexit cleanup

set -A pooltype "" "mirror" "raidz" "raidz1" "raidz2"

#
# cleanup the pools created in previous case if zpool_create_004_pos timedout
#
for pool in $TESTPOOL2 $TESTPOOL1 $TESTPOOL; do
	destroy_pool -f $pool
done

#prepare raw file for file disk
[[ -d $TESTDIR ]] && $RM -rf $TESTDIR
log_must $MKDIR -p $TESTDIR
typeset -i i=1
while (( i < 4 )); do
	log_must $MKFILE -s $FILESIZE $TESTDIR/file.$i

	(( i = i + 1 ))
done

#Remove the directory with name as pool name if it exists
[[ -d /$TESTPOOL ]] && $RM -rf /$TESTPOOL
file=$TESTDIR/file

for opt in "-R $TESTDIR1" "-m $TESTDIR1" \
	"-R $TESTDIR1 -m $TESTDIR1" "-m $TESTDIR1 -R $TESTDIR1"
do
	i=0
	while (( i < ${#pooltype[*]} )); do
		#Remove the testing pool and its mount directory
		destroy_pool -f $TESTPOOL
		[[ -d $TESTDIR1 ]] && $RM -rf $TESTDIR1
		log_must $ZPOOL create $opt $TESTPOOL ${pooltype[i]} \
			$file.1 $file.2 $file.3
		! poolexists $TESTPOOL && \
			log_fail "Createing pool with $opt fails."
		mpt=`$ZFS mount | $EGREP "^$TESTPOOL[^/]" | $AWK '{print $2}'`
		(( ${#mpt} == 0 )) && \
			log_fail "$TESTPOOL created with $opt is not mounted."
		mpt_val=$(get_prop "mountpoint" $TESTPOOL)
		[[ "$mpt" != "$mpt_val" ]] && \
			log_fail "The value of mountpoint property is different\
				from the output of zfs mount"
		if [[ "$opt" == "-m $TESTDIR1" ]]; then
			[[ ! -d $TESTDIR1 ]] && \
				log_fail "$TESTDIR1 is not created auotmatically."
			[[ "$mpt" != "$TESTDIR1" ]] && \
				log_fail "$TESTPOOL is not mounted on $TESTDIR1."
		elif [[ "$opt" == "-R $TESTDIR1" ]]; then
			[[ ! -d $TESTDIR1/$TESTPOOL ]] && \
				log_fail "$TESTDIR1/$TESTPOOL is not created auotmatically."
			[[ "$mpt" != "$TESTDIR1/$TESTPOOL" ]] && \
				log_fail "$TESTPOOL is not mounted on $TESTDIR1/$TESTPOOL."
		else
			[[ ! -d ${TESTDIR1}$TESTDIR1 ]] && \
				log_fail "${TESTDIR1}$TESTDIR1 is not created automatically."
			[[ "$mpt" != "${TESTDIR1}$TESTDIR1" ]] && \
				log_fail "$TESTPOOL is not mounted on ${TESTDIR1}$TESTDIR1."
		fi
		[[ -d /$TESTPOOL ]] && \
			log_fail "The default mountpoint /$TESTPOOL is created" \
				"while with $opt option."

		(( i = i + 1 ))
	done
done

log_pass "'zpool create [-R root][-m mountpoint] <pool> <vdev> ...' works as expected."
