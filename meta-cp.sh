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


function create_file()
{
    local file="\$1";
    local acc="\$2";
    local size="\$3";
    local uid="\$4";
    local gid="\$5";

    touch "\$file";
    chmod "\$acc" "\$file";
    truncate -s "\$size" "\$file";
    chown -h "\$uid":"\$gid" "\$file";
}


function create_dir()
{
    local file="\$1";
    local acc="\$2";
    local uid="\$3";
    local gid="\$4";

    mkdir -p -m "\$acc" "\$file";
    chown -h "\$uid":"\$gid" "\$file";
}


function create_symlink()
{
    local file="\$1";
    local link="\$2";
    local uid="\$3";
    local gid="\$4";

    ln -s "\$link" "\$file";
    chown -h "\$uid":"\$gid" "\$file";
}


function create_fifo()
{
    local file="\$1";
    local acc="\$2";
    local uid="\$3";
    local gid="\$4";

    mkfifo -m "\$acc" "\$file";
    chown -h "\$uid":"\$gid" "\$file";
}


function create_block()
{
    local file="\$1";
    local acc="\$2";
    local maj="\$3";
    local min="\$4";
    local uid="\$5";
    local gid="\$6";

    mknod -m "\$acc" "\$file" b "\$maj" "\$min";
    chown -h "\$uid":"\$gid" "\$file";
}


function create_block()
{
    local file="\$1";
    local acc="\$2";
    local maj="\$3";
    local min="\$4";
    local uid="\$5";
    local gid="\$6";

    mknod -m "\$acc" "\$file" c "\$maj" "\$min";
    chown -h "\$uid":"\$gid" "\$file";
}


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

EOF
}


function body()
{
    local src="$1";
    local dst="$2";
    local line;
    local stats;

    cd $src;

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

	case "$type" in
	    'regular file'|'regular empty file')
		cat >> "$dst" <<EOF
create_file "$line" "$acc" "$size" "$uid" "$gid";
EOF
		;;
	    'directory')
		cat >> "$dst" <<EOF
create_dir "$line" "$acc" "$uid" "$gid";
EOF
		;;
	    'symbolic link')
		local link=$(readlink "$line");
		cat >> "$dst" <<EOF
create_symlink "$line" "$link" "$uid" "$gid";
EOF
		;;
	    'fifo')
		cat >> "$dst" <<EOF
create_fifo "$line" "$acc" "$uid" "$gid";
EOF
		;;
	    'block special file')
		cat >> "$dst" <<EOF
create_block "$line" "$acc" "$maj" "$min" "$uid" "$gid";
EOF
		;;
	    'character special file')
		cat >> "$dst" <<EOF
create_char "$line" "$acc" "$maj" "$min" "$uid" "$gid";
EOF
		;;
	    *)
		cat >> "$dst" <<EOF
echo Do not know how to recreate "$line" of type "$type";
EOF
		continue
		;;
	esac
    done
}


function footer()
{
    local src="$1";
    local dst="$2";
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
