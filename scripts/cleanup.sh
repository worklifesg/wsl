#!/bin/bash
set -e
apt-get autoremove -y || true
apt-get clean || true
rm -rf /var/cache/apt/* /tmp/* /var/tmp/*
exit 0