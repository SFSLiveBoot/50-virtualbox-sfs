#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"
. "$lbu/scripts/common.func"

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
