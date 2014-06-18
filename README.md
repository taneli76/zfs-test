This is (supposed to be) the ZFS Test Suite, with support for all platforms
that ZFS from Sun Solaris have been ported to.


To run the test suite, just issue the command

   make test

It will require that your environment is setup in a certain way, but
the Makefile will make sure to check this. Most of it any way...

To run specific gest group(s), make a copy of the

   cp test/zfs-tests/runfiles/linux.run test/zfs-tests/runfiles/linux.run.tmp

file, edit it (uncomment or delete all that shouldn't be run) and set
the RUNFILE variable:

     export RUNFILE="-c test/zfs-tests/runfiles/linux.run.tmp"


                             CAVEATS
========================================================================
* The user zfs-test needs to be able to run sudo without issuing a
  password.

* To run the Test Suite, it is also required that you have a built ZoL
  zfs repository in ../zfs.

* You will also need to verify that all the commands specified in
  test/zfs-tests/include/commands-linux.cfg exists.

* You will need quite a lot of free space on /var/tmp (which needs
  to be 'rwxrwxrwt') for temporary files etc. At least 16GB seems
  to be required.
