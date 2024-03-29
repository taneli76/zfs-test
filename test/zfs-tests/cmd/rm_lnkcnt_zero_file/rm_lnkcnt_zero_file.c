/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 */

/*
 * Copyright (c) 2012 by Delphix. All rights reserved.
 */

/*
 * --------------------------------------------------------------------
 * The purpose of this test is to see if the bug reported (#4723351) for
 * UFS exists when using a ZFS file system.
 * --------------------------------------------------------------------
 *
 */
#define	_REENTRANT 1
#include <stdio.h>
#include <fcntl.h>
#include <pthread.h>
#ifdef _LINUX
#include <string.h>
#include <libspl/thread.h>
#else
#include <thread.h>
#endif
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <unistd.h>
#include <strings.h>

#ifdef _LINUX
#ifndef HAVE_THR_SETCONCURRENCY
#define thr_setconcurrency(A) pthread_setconcurrency(A)
#endif
#endif

static const int TRUE = 1;
static char *filebase;

static int
pickidx(void)
{
	return (random() % 1000);
}

/* ARGSUSED */
static void *
mover(void *a)
{
	char buf[256];
	int idx, len, ret;

	len = strlen(filebase) + 5;

	while (TRUE) {
		idx = pickidx();
		(void) snprintf(buf, len, "%s.%03d", filebase, idx);
		ret = rename(filebase, buf);
		if (ret < 0 && errno != ENOENT)
			(void) perror("renaming file");
	}

	return (NULL);
}

/* ARGSUSED */
static void *
cleaner(void *a)
{
	char buf[256];
	int idx, len, ret;

	len = strlen(filebase) + 5;

	while (TRUE) {
		idx = pickidx();
		(void) snprintf(buf, len, "%s.%03d", filebase, idx);
		ret = remove(buf);
		if (ret < 0 && errno != ENOENT)
			(void) perror("removing file");
	}

	return (NULL);
}

static void *
writer(void *a)
{
	int *fd = (int *)a;

	while (TRUE) {
		(void) close (*fd);
		*fd = open(filebase, O_APPEND | O_RDWR | O_CREAT, 0644);
		if (*fd < 0)
			perror("refreshing file");
		(void) write(*fd, "test\n", 5);
	}

	return (NULL);
}

int
main(int argc, char **argv)
{
	int fd;
	pthread_t tid;

	if (argc == 1) {
		(void) printf("Usage: %s <filebase>\n", argv[0]);
		exit(-1);
	}

	filebase = argv[1];
	fd = open(filebase, O_APPEND | O_RDWR | O_CREAT, 0644);
	if (fd < 0) {
		perror("creating test file");
		exit(-1);
	}

	(void) thr_setconcurrency(4);	/* 3 threads + main */
	(void) pthread_create(&tid, NULL, mover, NULL);
	(void) pthread_create(&tid, NULL, cleaner, NULL);
	(void) pthread_create(&tid, NULL, writer, (void *) &fd);

	while (TRUE) {
		int ret;
		struct stat st;

		ret = stat(filebase, &st);
		if (ret == 0 && (st.st_nlink > 2 || st.st_nlink < 1)) {
			(void) printf("st.st_nlink = %d, exiting\n", \
			    (int)st.st_nlink);
			exit(0);
		}
		(void) sleep(1);
	}

	return (0);
}
