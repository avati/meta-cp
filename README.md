meta-cp
=======

Creates a meta-program to (mostly) recreate a data set

Usage
------

	src-sh# ls -l /source/directory
	<... stuff ...>

	src-sh# meta-cp.sh /source/directory capture.sh
	src-sh# gzip -9 capture.sh

	<... transport capture.sh.gz to destination machine ...>

	dst-sh# gzip -d capture.sh.gz
	dst-sh# ./capture.sh /dest/directory
	dst-sh# ls -l /dest/directory
	<... same stuff ...>
