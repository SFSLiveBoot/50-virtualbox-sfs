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

echo -n "Locating missing libraries.. "
ldconfig_p="$(mktemp)"
ldconfig -p >"$ldconfig_p"
for solib in $(find "$DESTDIR/usr/lib/virtualbox" -mindepth 1 -maxdepth 1 -type f -exec file {} + | grep ELF | cut -f1 -d: | xargs sh -c 'for elf;do objdump -x "$elf";done' _ | awk '/NEEDED/{print $2}' | sort -u);do
  if test -e "$DESTDIR/usr/lib/virtualbox/$solib";then continue
  elif grep -qFw "$solib" "$ldconfig_p";then continue
  else
    case "$solib" in
      libQt5OpenGL.so.5) add_dpkg="${add_dpkg:+$add_dpkg }libqt5opengl5" ;;
      libQtOpenGL.so.4) add_dpkg="${add_dpkg:+$add_dpkg }libqt4-opengl" ;;
      *) echo "Warning: Library '$solib' not found (unknown package)" >&2 ;;
    esac
  fi
done
echo "need to install: ${add_dpkg:-none}"
rm -f "$ldconfig_p"
test -z "$add_dpkg" || "$lbu/scripts/apt-sfs.sh" "$DESTDIR" $add_dpkg

echo -n "Setting suid permissions.. "
: "${vbox_suid:=VirtualBoxVM}"
test -e "$DESTDIR/usr/lib/virtualbox/$vbox_suid" || vbox_suid="VirtualBox"

find "$DESTDIR/usr/lib/virtualbox" \( \
  -name VBoxHeadless -o \
  -name VBoxNetAdpCtl -o \
  -name VBoxNetDHCP -o \
  -name VBoxNetNAT -o \
  -name VBoxSDL -o \
  -name VBoxVolInfo -o \
  -name "$vbox_suid" \) \
  -exec chmod -v 4511 {} +
echo "Ok."

if test -n "$ORACLE_PUEL_ACCEPT";then
  echo "Oracle PUEL accepted, installing extension pack"
  if test "x$ORACLE_PUEL_ACCEPT" = "xyes";then
    deb_ver="$(dpkg-deb -I "$deb" control | sed -ne '/^Version: /{s/.* //;s/-.*//;p;q}')"
    ext_pack="$(dl_file https://download.virtualbox.org/virtualbox/${deb_ver}/Oracle_VM_VirtualBox_Extension_Pack-${deb_ver}.vbox-extpack)"
  else
    ext_pack="$ORACLE_PUEL_ACCEPT"
  fi
  echo -n "Installing $ext_pack .. "
  ext_dir="$DESTDIR/usr/lib/virtualbox/ExtensionPacks/Oracle_VM_VirtualBox_Extension_Pack"
  mkdir -p "$ext_dir"
  tar xfz "$ext_pack" --no-same-owner --no-same-permission -C "$ext_dir"
  echo "Done."
else
  echo "If you accept Oracle Extension Pack PUEL, you can set ORACLE_PUEL_ACCEPT env var to 'yes' or to a downloaded extpack file"
fi

echo "Ok."
