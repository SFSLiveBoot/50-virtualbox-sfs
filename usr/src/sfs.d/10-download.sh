#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"
. "$lbu/scripts/common.func"

echo -n "Downloading latest .deb .. "
deb="$(dl_file "$(latest_url)")"
echo "ok."

echo -n "Unpacking ${deb##*/} .. "
unpack_deb "$DESTDIR" "$deb"
echo "Ok."
