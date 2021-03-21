#!/bin/sh
set -e

CHARTS_BASE=/var/lib/rancher/k3s/server/static/charts
MANIFESTS_BASE=/var/lib/rancher/k3s/server/manifests
MY_PATH="`dirname \"$0\"`"

cd ${MY_PATH}
info() {
    echo '[INFO] ' "$@"
}

dashboard() {
    CHARTS=$1
    MANIFESTS=$2
    
    tar -cvzf ${CHARTS}/kubernetes-dashboard-4.0.2.tgz kubernetes-dashboard
    cp dashboard.yaml ${MANIFESTS}/dashboard.yaml 
}

registry() {
    CHARTS=$1
    MANIFESTS=$2
    
    tar -cvzf ${CHARTS}/docker-registry-1.10.1.tgz docker-registry
    cp registry.yaml ${MANIFESTS}/registry.yaml
}

alertmanager() {
    CHARTS=$1
    MANIFESTS=$2
    
    tar -cvzf ${CHARTS}/alertmanager-0.8.0.tgz alertmanager
    cp alertmanager.yaml ${MANIFESTS}/alertmanager.yaml
}

prometheus() {
    CHARTS=$1
    MANIFESTS=$2
    
    tar -cvzf ${CHARTS}/prometheus-13.6.0.tgz prometheus
    cp prometheus.yaml ${MANIFESTS}/prometheus.yaml
}

ingress() {
    CHARTS=$1
    MANIFESTS=$2
    
    #tar -cvzf ${CHARTS}/docker-registry-1.10.1.tgz docker-registry
    cp ingress.yaml ${MANIFESTS}/ingress.yaml
}


dashboard  $CHARTS_BASE $MANIFESTS_BASE
registry  $CHARTS_BASE $MANIFESTS_BASE
ingress  $CHARTS_BASE $MANIFESTS_BASE
#alertmanager $CHARTS_BASE $MANIFESTS_BASE
#prometheus $CHARTS_BASE $MANIFESTS_BASE


