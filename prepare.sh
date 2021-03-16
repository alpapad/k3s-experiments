export PATH=/usr/sbin/:/usr/bin/:/bin:/usr/libexec/cni/


export REPO="docker.io/"


docker pull ${REPO}rancher/k3s:v1.20.4-k3s1

docker tag ${REPO}rancher/k3s:v1.20.4-k3s1 rancher/k3s:v1.20.4-k3s1

docker create --name k3scontainer rancher/k3s:v1.20.4-k3s1
docker cp k3scontainer:/bin/containerd k3s
docker cp k3scontainer:/bin/runc runc
docker cp k3scontainer:/bin/cni cni
docker cp k3scontainer:/bin/containerd-shim-runc-v2 containerd-shim-runc-v2
docker cp k3scontainer:/bin/containerd-shim containerd-shim
docker cp k3scontainer:/bin/check-config check-config

docker rm k3scontainer


docker pull ${REPO}rancher/coredns-coredns:1.8.0
docker pull ${REPO}rancher/klipper-helm:v0.4.3
docker pull ${REPO}rancher/klipper-lb:v0.1.2
docker pull ${REPO}rancher/library-busybox:1.32.1
docker pull ${REPO}rancher/library-traefik:1.7.19
docker pull ${REPO}rancher/local-path-provisioner:v0.0.19
docker pull ${REPO}rancher/metrics-server:v0.3.6
docker pull ${REPO}rancher/pause:3.1

docker pull ${REPO}kubernetesui/dashboard:v2.0.0
docker pull ${REPO}kubernetesui/metrics-scraper:v1.0.6

# quay.io/prometheus/alertmanager tag: v0.21.0
# jimmidyson/configmap-reload tag: v0.5.0
# quay.io/prometheus/node-exporter tag: v1.0.1
# quay.io/prometheus/prometheus tag: v2.24.0
# prom/pushgateway tag: v1.3.1

docker tag ${REPO}rancher/coredns-coredns:1.8.0 rancher/coredns-coredns:1.8.
docker tag ${REPO}rancher/klipper-helm:v0.4.3 rancher/klipper-helm:v0.4.3
docker tag ${REPO}rancher/klipper-lb:v0.1.2 rancher/klipper-lb:v0.1.2
docker tag ${REPO}rancher/library-busybox:1.32.1 rancher/library-busybox:1.32.1
docker tag ${REPO}rancher/library-traefik:1.7.19 rancher/library-traefik:1.7.19
docker tag ${REPO}rancher/local-path-provisioner:v0.0.19 rancher/local-path-provisioner:v0.0.19
docker tag ${REPO}rancher/metrics-server:v0.3.6 rancher/metrics-server:v0.3.6
docker tag ${REPO}rancher/pause:3.1 rancher/pause:3.1

docker tag ${REPO}kubernetesui/dashboard:v2.0.0 kubernetesui/dashboard:v2.0.0
docker tag ${REPO}kubernetesui/metrics-scraper:v1.0.6 kubernetesui/metrics-scraper:v1.0.6


docker save -o k3s-airgap-images-amd64.tar rancher/coredns-coredns:1.8.0 rancher/klipper-helm:v0.4.3 rancher/klipper-lb:v0.1.2 rancher/library-busybox:1.32.1 rancher/library-traefik:1.7.19 rancher/local-path-provisioner:v0.0.19 rancher/metrics-server:v0.3.6 rancher/pause:3.1 kubernetesui/dashboard:v2.0.0 kubernetesui/metrics-scraper:v1.0.6


mkdir -p /var/lib/rancher/k3s/agent/images/
cp ./k3s-airgap-images-amd64.tar /var/lib/rancher/k3s/agent/images/


mkdir -p /opt/k3s/bin
cp k3s /opt/k3s/bin/
cp cni /opt/k3s/bin/

cp runc /opt/k3s/bin/
cp containerd-shim-runc-v2 /opt/k3s/bin/
cp containerd-shim /opt/k3s/bin/
cp check-config /opt/k3s/bin/

CDW=`pwd`

cd /opt/k3s/bin/
ln -sf k3s kubectl
ln -sf k3s crictl
ln -sf k3s ctr
ln -sf k3s containerd
ln -sf k3s k3s-server
ln -sf k3s k3s-etcd-snapshot
ln -sf k3s k3s-agent


ln -sf cni host-local
ln -sf cni bandwidth
ln -sf cni bridge
ln -sf cni dhcp
ln -sf cni dnsname
ln -sf cni firewall
ln -sf cni ipvlan
ln -sf cni loopback
ln -sf cni host-device
ln -sf cni macvlan
ln -sf cni portmap
ln -sf cni ptp
ln -sf cni sbr
ln -sf cni static
ln -sf cni tuning
ln -sf cni vlan
ln -sf cni vrf
#ln -sf cni ip-tables
ln -sf cni flannel
#ln -sf cni iptables

cd $CWD
#./k3s server --selinux


INSTALL_K3S_SKIP_ENABLE=true \
	INSTALL_K3S_SKIP_START=true \
	INSTALL_K3S_SKIP_DOWNLOAD=true \
	INSTALL_K3S_BIN_DIR=/opt/k3s/bin \
	INSTALL_K3S_SELINUX_WARN=true \
	INSTALL_K3S_SKIP_SELINUX_RPM=true \
	/bin/sh ./install.sh 

# /opt/k3s/bin/:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin
