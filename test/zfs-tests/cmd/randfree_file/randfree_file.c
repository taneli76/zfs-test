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

#include "../file_common.h"

#ifdef _LINUX
/* Defined in <spl_repo>/spl/include/sys/{vnode,fcntl}.h */
#define F_FREESP        11	/* Free file space */
#endif

/*
 * Create a file with assigned size and then free the specified
 * section of the file
 */

static void usage(char *progname);

static void
usage(char *progname)
{
	(void) fprintf(stderr,
	    "usage: %s [-l filesize] [-s start-offset]"
	    "[-n section-len] filename\n", progname);
	exit(1);
}

int
main(int argc, char *argv[])
{
	char *filename = NULL;
	char *buf;
	size_t filesize = 0;
	off_t start_off = 0;
	off_t off_len = 0;
	int  fd, ch;
	struct flock fl;
	mode_t mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;

	while ((ch = getopt(argc, argv, "l:s:n:")) != EOF) {
		switch (ch) {
		case 'l':
			filesize = atoll(optarg);
			break;
		case 's':
			start_off = atoll(optarg);
			break;
		case 'n':
			off_len = atoll(optarg);
			break;
		default:
			usage(argv[0]);
			break;
		}
	}

	if (optind == argc - 1)
		filename = argv[optind];
	else
		usage(argv[0]);

	buf = (char *)malloc(filesize);

	if ((fd = open(filename, O_RDWR | O_CREAT | O_TRUNC, mode)) < 0) {
		perror("open");
		return (1);
	}
	if (write(fd, buf, filesize) < filesize) {
		perror("write");
		return (1);
	}
	fl.l_whence = SEEK_SET;
	fl.l_start = start_off;
	fl.l_len = off_len;
	if (fcntl(fd, F_FREESP, &fl) != 0) {
		perror("fcntl");
		return (1);
	}

	free(buf);
	return (0);
}
