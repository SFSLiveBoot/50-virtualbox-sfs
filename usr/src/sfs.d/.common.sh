: ${lbu:=/opt/LiveBootUtils}

: ${dist:=$(awk '/^deb /{print $3}' /etc/apt/sources.list | head -1)}
: ${debarch:=$(dpkg --print-architecture)}

: ${repo:=http://download.virtualbox.org/virtualbox/debian}
: ${package_name:=virtualbox-7.0}
: ${packages_url:=$repo/dists/$dist/contrib/binary-$debarch/Packages.gz}

latest_ver() {
  curl -s "$packages_url" | gzip -dc | grep -e ^Package: -e ^Version: | grep -FxA1 "Package: $package_name" | awk '/^Version: /{print $2}'
}

latest_url() {
    echo "$repo/$(curl -s "$packages_url" | gzip -dc | grep -e ^Package: -e ^Filename: | grep -FxA1 "Package: $package_name" | awk '/^Filename: /{print $2}')"
}

installed_ver() {
  find "$DESTDIR/var/lib/dpkg/info" -name "virtualbox-[0-9]*.control" -exec awk '/^Version: /{print $2}' {} +
}
