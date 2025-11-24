#!/bin/bash
set -e

# Build script that creates rootfs via debootstrap then produces custom-wsl.tar.gz
# Run as root or with sudo (CodeBuild will run inside a Linux container)

WORKDIR=$(pwd)
ROOTFS=$WORKDIR/rootfs
OUT=$WORKDIR/custom-wsl.tar.gz

echo "[+] Cleaning previous runs..."
rm -rf "$ROOTFS" "$OUT"
mkdir -p "$ROOTFS"

RELEASE=focal
MIRROR=http://archive.ubuntu.com/ubuntu/

echo "[+] Running debootstrap for $RELEASE..."
sudo debootstrap --variant=minbase $RELEASE "$ROOTFS" $MIRROR

echo "[+] Copying configuration files..."
sudo cp -a wsl.conf "$ROOTFS/etc/wsl.conf" || true
sudo cp -a install-packages.sh "$ROOTFS/root/install-packages.sh"
if [ -f packages.txt ]; then
    sudo cp -a packages.txt "$ROOTFS/root/packages.txt"
fi
sudo cp -a scripts/cleanup.sh "$ROOTFS/root/cleanup.sh"
sudo chmod +x "$ROOTFS/root/install-packages.sh" "$ROOTFS/root/cleanup.sh"

# Bind mounts required to run apt, chroot, etc.
sudo mount --bind /dev "$ROOTFS/dev" || true
sudo mount --bind /proc "$ROOTFS/proc" || true
sudo mount --bind /sys "$ROOTFS/sys" || true
sudo cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

echo "[+] Running package installation inside chroot..."
sudo chroot "$ROOTFS" /bin/bash -c "/root/install-packages.sh"

echo "[+] Running cleanup inside chroot..."
sudo chroot "$ROOTFS" /bin/bash -c "/root/cleanup.sh"

sudo umount "$ROOTFS/dev" || true
sudo umount "$ROOTFS/proc" || true
sudo umount "$ROOTFS/sys" || true

sudo rm -rf "$ROOTFS/var/lib/apt/lists/*"

echo "[+] Creating tarball $OUT"
sudo tar -C "$ROOTFS" -czf "$OUT" .
sudo chown "$(id -u):$(id -g)" "$OUT"

echo "[+] Done: $OUT"