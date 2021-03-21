#!/bin/sh
set -e

systemctl stop k3s || true
if [ -f /opt/k3s/bin/k3s-killall.sh  ]; then
	/opt/k3s/bin/k3s-killall.sh || true
	/opt/k3s/bin/k3s-uninstall.sh  || true
fi
rm -rf /opt/k3s/ || true
rm -rf /etc/rancher || true
rm -rf /var/lib/rancher || true
