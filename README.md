meta-cp
=======

Meta program to create program to (mostly) recreate a data set

Usage
------

	src-sh# ls -l /source/directory
	<... stuff ...>

	src-sh# meta-cp.sh /source/directory | gzip -9c - > capture.sh.gz

	<... transport capture.sh.gz to destination machine ...>

	dst-sh# gzip -d capture.sh.gz
	dst-sh# ./capture.sh /dest/directory
	dst-sh# ls -l /dest/directory
	<... same stuff ...>
