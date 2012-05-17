#!/bin/bash -e
#
#  Script which accepts a path to a data set (directory) and creates
#  a script which accepts a path where the data set is re-created
#
#  This version of the script intentionally skips the file contents
#  and instead sets the truncates the new file to the original file size
#
#  - Anand Avati <avati@redhat.com>
#

function header()
{
    local src="$1";
    local dst="$2";

    cat > "$dst" <<EOF
#!/bin/bash -e

function main()
{
    if [ \$# -ne 1 ]; then
        echo "Usage: \$0 <dst-dir>";
        exit 1;
    fi

    dst="\$1";

    if [ -e "\$dst" -a ! -d "\$dst" ]; then
        echo "FATAL: \$dst - not a directory";
        exit 1;
    fi

    mkdir -p "\$dst";

    cd "\$dst";

    dump;
}

EOF
}


function body()
{
    local src="$1";
    local dst="$2";
    local line;
    local stats;

    cd $src;

cat >> "$dst" <<EOF
function dump()
{
EOF
    find . | while read line; do
	stats=$(stat -c '"%F" %u %g %a %s %t %T' "$line");
	eval "set $stats";
	type="$1";
	uid="$2";
	gid="$3";
	acc="$4";
	size="$5";
	maj="$6";
	min="$7";
	link="$8";

	cat >> "$dst" <<EOF

    # name="$line",type="$type",uid="$uid",gid="$gid",acc="$acc",size="$size",maj="$maj",min="$min"
EOF
	case "$1" in
	    'regular file'|'regular empty file')
		cat >> "$dst" <<EOF
    \$E touch "$line";
    \$E chmod "$acc" "$line";
    \$E truncate -s "$size" "$line";
EOF
		;;
	    'directory')
		cat >> "$dst" <<EOF
    \$E mkdir -p -m "$acc" "$line";
EOF
		;;
	    'symbolic link')
		local link=$(readlink "$line");
		cat >> "$dst" <<EOF
    \$E ln -s "$link" "$line";
EOF
		;;
	    'fifo')
		cat >> "$dst" <<EOF
    \$E mkfifo -m "$acc" "$line";
EOF
		;;
	    'block special file')
		cat >> "$dst" <<EOF
    \$E mknod -m "$acc" "$line" b $maj $min;
EOF
		;;
	    'character special file')
		cat >> "$dst" <<EOF
    \$E mknod -m "$acc" "$line" c $maj $min;
EOF
		;;
	    *)
		cat >> "$dst" <<EOF
    echo Do not know how to recreate "$line"
EOF
		continue
		;;
	esac

	cat >> "$dst" <<EOF
    \$E chown -h "$uid":"$gid" "$line";
EOF
    done

cat >> "$dst" <<EOF

}

EOF
}


function footer()
{
    local src="$1";
    local dst="$2";

    cat >> "$dst" <<EOF
main "\$@";
EOF
}


function main()
{
    if [ $# -lt 1 -o $# -gt 2 ]; then
	echo "Usage: $0 <src-dir> [output.sh]"
	exit 1
    fi

    local src="$1";

    if [ ! -d "$src" ]; then
	echo "FATAL: $src must be a directory"
	exit 1
    fi

    local dst;

    if [ $# -gt 1 ]; then
	dst="$2";
    else
	dst="/dev/stdout";
    fi

    : > "$dst";

    header "$src" "$dst";
    body "$src" "$dst";
    footer "$src" "$dst";
}

main "$@";
