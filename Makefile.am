SUBDIRS  = tests/functional/ctime tests/functional/exec cmd/chg_usr_exec
SUBDIRS := cmd/mktree cmd/file_write cmd/mkbusy cmd/randfree_file
SUBDIRS := cmd/largest_file cmd/rm_lnkcnt_zero_file cmd/readmmap
SUBDIRS := cmd/mmapwrite cmd/file_trunc cmd/file_check

abs_top_srcdir = /usr/src/zfs-test
SHELL = /bin/bash

ctags:
	$(RM) $(top_srcdir)/tags
	find $(top_srcdir) -name .git -prune -o -name '*.[hc]' | xargs ctags

etags:
	$(RM) $(top_srcdir)/TAGS
	find $(top_srcdir) -name .pc -prune -o -name '*.[hc]' | xargs etags -a

test: test_verify test/zfs-tests/cmd
	@SRC=$(abs_top_srcdir) \
	 STF_TOOLS=$(abs_top_srcdir)/test/test-runner/stf \
	 STF_SUITE=$(abs_top_srcdir)/test/zfs-tests \
	 DISKS="$(shell for i in {1..3}; do \
	    rm -f /var/tmp/zfs_test-$$i; \
	    $(abs_top_srcdir)/scripts/mkfile -s 25000m /var/tmp/zfs_test-$$i; \
	    echo "/var/tmp/zfs_test-$$i "; \
	   done)" \
	 su zfs-tests -c "ksh $(abs_top_srcdir)/test/zfs-tests/cmd/scripts/zfstest.ksh $$RUNFILE"

test_verify:
	@# -------------------------------------------------------------------
	@# adduser --home /var/tmp/test_results --shell /usr/bin/ksh --gecos "ZFS Test Suite" --disabled-password zfs-tests
	@# echo 'zfs-tests	ALL = NOPASSWD: ALL' >> /etc/sudoers
	@# mkdir /opt && cd /opt
	@# ln -s $(top_srcdir)/test/test-runner .
	@# ln -s $(top_srcdir)/test/zfs-tests .
	@# -------------------------------------------------------------------
	@( if ! id zfs-tests > /dev/null 2>&1; then \
		echo "ERROR: You must create a zfs-test user to run the test as."; \
		exit 1; \
	   fi; \
	   if [ ! -L /opt/test-runner ]; then \
		echo "ERROR: You will need to create the /opt/test-runner link"; \
		echo "       pointing to `pwd`/test/test-runner."; \
		exit 1; \
	   fi; \
	   if [ ! -L /opt/zfs-tests ]; then \
		echo "ERROR: You will need to create the /opt/test-runner link"; \
		echo "       pointing to `pwd`/test/zfs-tests."; \
		exit 1; \
	   fi; \
	   if [ `zpool list -H | wc -l` -gt 0 ]; then \
		echo "ERROR: You can't be running a pool - it will be destroyed!"; \
		exit 1; \
	   fi; \
	   missing=`for cmd in \`grep '="/' test/zfs-tests/include/commands-linux.cfg | sed -e "s@.*=\"@@" -e 's@ .*@@' -e 's@"@@'\`; do \
		if [ ! -x "$$cmd" ]; then \
			echo "$$cmd"; \
		fi; \
	   done`; \
	   if [ -n "$$missing" ]; then \
		echo "Missing commands: '$$missing'"; \
	   fi)

test/zfs-tests/cmd:
	@(for subdir in $(SUBDIRS); do \
		make -C test/zfs-tests/$$subdir -f Makefile.linux; \
	done)

cleanup:
	@(for subdir in $(SUBDIRS); do \
		make -C test/zfs-tests/$$subdir -f Makefile.linux; \
	done)

tags: ctags etags

.PHONY: test test/zfs-tests/cmd

# Tell versions [3.59,3.63) of GNU make to not export all variables.
# Otherwise a system limit (for SysV at least) may be exceeded.
.NOEXPORT:
