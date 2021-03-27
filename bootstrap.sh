#!/bin/bash -e

DISTRO=$1
EXCLUDE="libext2fs2 e2fsprogs ncurses-bin"
MIRROR=${2:-http://deb.debian.org/debian}

for ARCHITECTURE in $ARCHS; do
  WORK_DIR="$ARCHITECTURE/$DISTRO"
  rm -rf "$ARCHITECTURE" || true
  mkdir -p "$ARCHITECTURE"

  debootstrap --foreign --variant=minbase --components=main,contrib,non-free \
    --exclude="$EXCLUDE" --arch="$ARCHITECTURE" "$DISTRO" "$WORK_DIR" "$MIRROR"

  # if [ "${ARCHITECTURE}" = "arm64" ]; then
  #   QEMU_BIN="/usr/bin/qemu-aarch64-static"
  #   mkdir -p "$WORK_DIR"/usr/bin/
  #   cp $QEMU_BIN "$WORK_DIR"/usr/bin/
  # elif [ "${ARCHITECTURE}" = "armhf" ]; then
  #   QEMU_BIN="/usr/bin/qemu-arm-static"
  #   mkdir -p "$WORK_DIR"/usr/bin/
  #   cp $QEMU_BIN "$WORK_DIR"/usr/bin/
  # fi

  echo 'Acquire::Languages "none";' >"$WORK_DIR"/etc/apt/apt.conf.d/docker-no-languages
  echo 'force-unsafe-io' >"$WORK_DIR"/etc/dpkg/dpkg.cfg.d/docker-apt-speedup

  aptGetClean='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'
  cat >"$WORK_DIR/etc/apt/apt.conf.d/docker-clean" <<-EOF
DPkg::Post-Invoke { ${aptGetClean} };
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";
EOF

  cat >"$WORK_DIR"/etc/apt/apt.conf.d/99_norecommends <<EOF
APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
EOF

  cat >"$WORK_DIR"/etc/dpkg/dpkg.cfg.d/01_no_doc <<EOF
path-exclude /usr/lib/systemd/catalog/*
path-exclude /usr/share/doc/*
path-include /usr/share/doc/*/copyright
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*
path-exclude /usr/share/locale/*
path-include /usr/share/locale/locale.alias
EOF
  cat >"$WORK_DIR/usr/sbin/policy-rc.d" <<-'EOF'
#!/bin/sh
exit 101
EOF
  chmod +x "$WORK_DIR/usr/sbin/policy-rc.d"

  on_chroot() {
    LC_ALL=C setarch "$(arch)" capsh --drop=cap_setfcap "--chroot=$WORK_DIR/" -- -e "$@"
  }

  on_chroot /debootstrap/debootstrap --second-stage

  rm -rf "$WORK_DIR"/usr/bin/qemu-* || true
  rm -rf "$WORK_DIR"/var/lib/apt/lists/* || true
  rm -rf "$WORK_DIR"/var/cache/apt/*.bin || true
  rm -rf "$WORK_DIR"/var/cache/apt/archives/*.deb || true
  rm -rf "$WORK_DIR"/usr/share/man/* || true
  rm -rf "$WORK_DIR"/usr/share/locale/* || true
  rm -rf "$WORK_DIR"/var/lib/dpkg/*-old || true
  rm -rf "$WORK_DIR"/var/cache/debconf/*-old || true
  rm -rf "$WORK_DIR"/etc/*- || true
  find "$WORK_DIR"/var/log -depth -type f -print0 | xargs -0 truncate -s 0
  find "$WORK_DIR"/usr/share/doc -depth -type f ! -name copyright -print0 | xargs -0 rm
  find "$WORK_DIR"/usr/share/doc -empty -print0 | xargs -0 rmdir
  mkdir -p "$WORK_DIR"/var/lib/apt/lists/partial

  tar -I 'pixz -1' -C "$WORK_DIR" -pcf "$ARCHITECTURE"."$DISTRO".minbase.tar.xz .

done
