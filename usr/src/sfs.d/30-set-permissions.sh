#!/bin/sh

set -e
. "$(dirname "$0")/.common.sh"
. "$lbu/scripts/common.func"

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
