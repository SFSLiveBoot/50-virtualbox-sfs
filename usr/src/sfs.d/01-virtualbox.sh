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
find "$DESTDIR/usr/lib/virtualbox" \( \
  -name VBoxHeadless -o \
  -name VBoxNetAdpCtl -o \
  -name VBoxNetDHCP -o \
  -name VBoxNetNAT -o \
  -name VBoxSDL -o \
  -name VBoxVolInfo -o \
  -name VirtualBox \) \
  -exec chmod -v 4511 {} +
echo "Ok."

dpkg -s libqt4-opengl | grep -q "^Status.*installed" || "$lbu/scripts/apt-sfs.sh" "$DESTDIR" libqt4-opengl

echo -n "Creating dkms links .. "
mod_name="$(find  "$DESTDIR/usr/src" -maxdepth 1 -name vboxhost-\* -printf "%f")"

test -z "$mod_name" || {
  mod_ver="${mod_name#vboxhost-}"

  test -s "$DESTDIR/usr/src/$mod_name/dkms.conf" || cat >"$DESTDIR/usr/src/$mod_name/dkms.conf" <<EOF
PACKAGE_NAME="vboxhost"
PACKAGE_VERSION="$mod_ver"

AUTOINSTALL=yes

BUILT_MODULE_NAME[0]="vboxdrv"
BUILT_MODULE_LOCATION[0]="vboxdrv"
DEST_MODULE_LOCATION[0]="/extra"

BUILT_MODULE_NAME[1]="vboxpci"
BUILT_MODULE_LOCATION[1]="vboxpci"
DEST_MODULE_LOCATION[1]="/extra"

BUILT_MODULE_NAME[2]="vboxnetadp"
BUILT_MODULE_LOCATION[2]="vboxnetadp"
DEST_MODULE_LOCATION[2]="/extra"

BUILT_MODULE_NAME[3]="vboxnetflt"
BUILT_MODULE_LOCATION[3]="vboxnetflt"
DEST_MODULE_LOCATION[3]="/extra"
EOF

  mkdir -p "$DESTDIR/var/lib/dkms/vboxhost/$mod_ver/build"
  ln -s "/usr/src/$mod_name" "$DESTDIR/var/lib/dkms/vboxhost/$mod_ver/source"
}

if test -n "$ORACLE_EXT_PACK";then
  echo -n "Installing $ORACLE_EXT_PACK .. "
  ext_dir="$DESTDIR/usr/lib/virtualbox/ExtensionPacks/Oracle_VM_VirtualBox_Extension_Pack"
  mkdir -p "$ext_dir"
  tar xfz "$ORACLE_EXT_PACK" --no-same-owner -C "$ext_dir"
  echo "Done."
else
  echo "If you accept Oracle Extension Pack PUEL, you can set ORACLE_EXT_PACK env var to downloaded extpack file"
fi

echo "Ok."
