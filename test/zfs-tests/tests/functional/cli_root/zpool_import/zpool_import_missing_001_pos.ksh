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
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2012 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.shlib
. $STF_SUITE/tests/functional/cli_root/zfs_mount/zfs_mount.kshlib
. $STF_SUITE/tests/functional/cli_root/zpool_import/zpool_import.cfg

#
# DESCRIPTION:
#	Once a pool has been exported, and one or more devices are
#	damaged or missing (d/m), import should handle this kind of situation
#	as described:
#		- Regular, report error while any number of devices failing.
#		- Mirror could withstand (N-1) devices failing
#		  before data integrity is compromised
#		- Raidz could withstand one devices failing
#		  before data integrity is compromised
#	Verify those are true.
#
# STRATEGY:
#	1. Create test pool upon device files using the various combinations.
#		- Regular pool
#		- Mirror
#		- Raidz
#	2. Create necessary filesystem and test files.
#	3. Export the test pool.
#	4. Remove one or more devices
#	5. Verify 'zpool import' will handle d/m device successfully.
#	   Using the various combinations.
#		- Regular import
#		- Alternate Root Specified
#	   It should be succeed with single d/m device upon 'raidz' & 'mirror',
#	   but failed against 'regular' or more d/m devices.
#	6. If import succeed, verify following is true:
#		- The pool shows up under 'zpool list'.
#		- The pool's health should be DEGRADED.
#		- It contains the correct test file
#

verify_runnable "global"

set -A vdevs "" "mirror" "raidz"
set -A options "" "-R $ALTER_ROOT"

function cleanup
{
	# recover the vdevs
	recreate_files

	[[ -d $ALTER_ROOT ]] && \
		log_must $RM -rf $ALTER_ROOT
}

function recreate_files
{
	destroy_dataset $TESTPOOL1/$TESTFS
	destroy_pool -f $TESTPOOL1

	log_must $RM -rf $DEVICE_DIR/*
	typeset i=0
	while (( i < $MAX_NUM )); do
		log_must $MKFILE -s $FILE_SIZE ${DEVICE_DIR}/${DEVICE_FILE}$i
		((i += 1))
	done
}

log_onexit cleanup

log_assert "Verify that import could handle damaged or missing device."

CWD=$PWD
cd $DEVICE_DIR || log_fail "Unable change directory to $DEVICE_DIR"

checksum1=$($SUM $MYTESTFILE | $AWK '{print $1}')

typeset -i i=0
typeset -i j=0
typeset -i count=0
typeset basedir backup

while (( i < ${#vdevs[*]} )); do

	setup_filesystem "$DEVICE_FILES" \
		$TESTPOOL1 $TESTFS $TESTDIR1 \
		"" ${vdevs[i]}

	backup=""

	guid=$(get_config $TESTPOOL1 pool_guid)
	log_must $CP $MYTESTFILE $TESTDIR1/$TESTFILE0

	log_must $ZFS umount $TESTDIR1

	j=0
	while (( j <  ${#options[*]} )); do

		count=0
		action=log_must

		#
		# Restore all device files.
		#
		[[ -n $backup ]] && \
			log_must $TAR $unpack_opts $DEVICE_DIR/$DEVICE_ARCHIVE

		for device in $DEVICE_FILES ; do
			log_must $RM -f $device

			poolexists $TESTPOOL1 && \
				log_must $ZPOOL export $TESTPOOL1

			#
			# Backup all device files while filesystem prepared.
			#
			if [[ -z $backup ]]; then
				log_must $TAR $pack_opts $DEVICE_DIR/$DEVICE_ARCHIVE \
					${DEVICE_FILE}*
				backup="true"
			fi

			(( count = count + 1 ))

			case "${vdevs[i]}" in
				'mirror') (( count == $GROUP_NUM )) && \
						action=log_mustnot
					;;
				'raidz')  (( count > 1 )) && \
						action=log_mustnot
					;;
				'')  action=log_mustnot
					;;
			esac

			typeset target=$TESTPOOL1
			if (( RANDOM % 2 == 0 )) ; then
				target=$guid
				log_note "Import by guid."
			fi
			$action $ZPOOL import \
				-d $DEVICE_DIR ${options[j]} $target

			[[ $action == "log_mustnot" ]] && continue

			log_must poolexists $TESTPOOL1

			health=$($ZPOOL list -H -o health $TESTPOOL1)

			[[ $health == "DEGRADED" ]] || \
				log_fail "$TESTPOOL1: Incorrect health($health)"
			log_must ismounted $TESTPOOL1/$TESTFS

			basedir=$TESTDIR1
			[[ -n ${options[j]} ]] && \
				basedir=$ALTER_ROOT/$TESTDIR1

			[[ ! -e $basedir/$TESTFILE0 ]] && \
				log_fail "$basedir/$TESTFILE0 missing after import."

			checksum2=$($SUM $basedir/$TESTFILE0 | $AWK '{print $1}')
			[[ "$checksum1" != "$checksum2" ]] && \
				log_fail "Checksums differ ($checksum1 != $checksum2)"

		done

		((j = j + 1))
	done

	recreate_files

	((i = i + 1))
done

log_pass "Import could handle damaged or missing device."
