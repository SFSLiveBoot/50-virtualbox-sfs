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

test ! -d "$DESTDIR/lib/modules" || {
  echo -n "Removing unnecessary modules .. "
  find "$DESTDIR/lib/modules" -mindepth 1 -maxdepth 1 -not -name "$(uname -r)" -exec rm -vr {} +
  echo "Ok."
}

echo -n "Setting suid permissions.. "
find "$DESTDIR/usr/lib/virtualbox" \
  -name VBoxHeadless -o \
  -name VBoxNetAdpCtl -o \
  -name VBoxNetDHCP -o \
  -name VBoxNetNAT -o \
  -name VBoxSDL -o \
  -name VBoxVolInfo -o \
  -name VirtualBox \
  -exec chmod -v 4511 {} +
echo "Ok."

dpkg -s libqt4-opengl | grep -q "^Status.*installed" || "$lbu/scripts/apt-sfs.sh" "$DESTDIR" libqt4-opengl

echo -n "Creating dkms links .. "
mod_name="$(find  "$DESTDIR/usr/src" -maxdepth 1 -name vboxhost-\* -printf "%f")"
test -z "$mod_name" || {
  mod_ver="${mod_name#vboxhost-}"
  mkdir -p "$DESTDIR/var/lib/dkms/vboxhost/$mod_ver/build"
  ln -s "/usr/src/$mod_name" "$DESTDIR/var/lib/dkms/vboxhost/$mod_ver/source"
}
echo "Ok."
