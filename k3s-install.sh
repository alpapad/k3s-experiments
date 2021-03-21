#!/bin/sh
set -e

CURDIR="`dirname \"$0\"`"



export YUM="dnf"

export REPO="docker.io/"





info() {
    echo '[INFO] ' "$@"
}
os_setup(){
    info "Prepare environment"
    $YUM -y install conntrack-tools
    
    chmod +x ./charts/deploy_charts.sh
    chmod +x ./_install.sh
    chmod +x ./uninstall.sh
}

k3s_binaries() {
    info "Extracting k3s:$2 to $3 (using repo $1)"
    REP=$1
    VER=$2
    DST=$3
    
    mkdir -p ${DST}
    docker pull ${REP}rancher/k3s:${VER}

    docker tag ${REP}rancher/k3s:${VER} rancher/k3s:${VER}

    docker create --name k3scontainer rancher/k3s:${VER}
    docker cp k3scontainer:/bin/containerd ${DST}/k3s
    docker cp k3scontainer:/bin/runc ${DST}/runc
    docker cp k3scontainer:/bin/cni ${DST}/cni
    docker cp k3scontainer:/bin/containerd-shim-runc-v2 ${DST}/containerd-shim-runc-v2
    docker cp k3scontainer:/bin/containerd-shim ${DST}/containerd-shim
    docker cp k3scontainer:/bin/check-config ${DST}/check-config
    
    docker rm k3scontainer
    
    for CMD in host-local bandwidth bridge dhcp dnsname firewall ipvlan loopback host-device macvlan portmap ptp sbr static tuning vlan vrf flannel
    do
        info "Linking  ${DST}/cni to ${DST}/${CMD}"
        ln -sf ${DST}/cni ${DST}/${CMD} 
    done
    
    
    for CMD in kubectl crictl ctr containerd k3s-server k3s-etcd-snapshot k3s-agent
    do
        info "Linking  ${DST}/k3s to ${DST}/${CMD}"
        ln -sf ${DST}/k3s ${DST}/${CMD} 
    done
}

k3s_images(){
    REP=$1

    IMG_LIST=()
    for IMG in $(cat images.txt )
    do
        docker pull ${REP}${IMG}
        docker tag ${REP}${IMG} ${IMG}
        IMG_LIST+="${IMG} "
    done
    
    info "Exporting $IMG_LIST to /var/lib/rancher/k3s/agent/images/k3s-airgap-images-amd64.tar"

    mkdir -p /var/lib/rancher/k3s/agent/images/
    docker save -o /var/lib/rancher/k3s/agent/images/k3s-airgap-images-amd64.tar ${IMG_LIST}
}

k3s_setup(){
    mkdir -p /opt/k3s/setup
    
    cp registries.yaml /opt/k3s/setup
    cp namespaces.yml /opt/k3s/setup
    cp security.yml /opt/k3s/setup
    
    #yes | cp -f charts/*.yaml /opt/k3s/setup
    #yes | cp -f charts/*.tgz /opt/k3s/setup
}

k3s_install(){
    DST=$1

    export INSTALL_K3S_SKIP_ENABLE=true
    export INSTALL_K3S_EXEC="--disable=traefik" 
    export INSTALL_K3S_SKIP_START=true 
    export INSTALL_K3S_SKIP_DOWNLOAD=true 
    export INSTALL_K3S_BIN_DIR=${DST}
    export INSTALL_K3S_SELINUX_WARN=true 
    export INSTALL_K3S_SKIP_SELINUX_RPM=true

    
    info "Installing k3s using binaries from $DST"
    
    ( exec  ./_install.sh )
    
    echo "PATH=$DST:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin" >> /etc/systemd/system/k3s.service.env
}

k3s_start(){
    info "Starting k3s service"
    systemctl daemon-reload
    systemctl start k3s
    
    info "Waiting for service to start"
    sleep 30
}

k3s_postinstall(){
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    
    /opt/k3s/bin/kubectl apply -f /opt/k3s/setup/namespaces.yml
    /opt/k3s/bin/kubectl apply -f /opt/k3s/setup/security.yml
    
    #yes | cp -f /opt/k3s/setup/*.tgz /var/lib/rancher/k3s/server/static/charts/
    #yes | cp -f /opt/k3s/setup/*.yaml /var/lib/rancher/k3s/server/manifests/
    
    ( exec ./charts/deploy_charts.sh )
}

k3s_logininfo(){
    info "k3s     dashboard at: https://dashboard.k3s.localhost/"
    info "traefik dashboard at: https://dashboard.k3s.localhost/"
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    
    info "Waiting for dashboard account to be created"
    sleep 30
    
    TOKENNAME=`/opt/k3s/bin/kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}"`
    info "Token entry to use is: $TOKENNAME"
    TOKEN=`/opt/k3s/bin/kubectl -n kubernetes-dashboard get secret $TOKENNAME -o jsonpath='{.data.token}'| base64 --decode`
    info "Token VALUE to use is: $TOKEN"
}

os_setup

k3s_binaries $REPO v1.20.4-k3s1 /opt/k3s/bin
k3s_images $REPO
k3s_setup
k3s_install /opt/k3s/bin
k3s_start
k3s_postinstall
k3s_logininfo
