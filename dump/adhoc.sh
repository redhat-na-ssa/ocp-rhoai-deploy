#!/bin/sh

scripts/bootstrap.sh

# adhoc for disconnected setup

install_quay(){
  ssh highside [ -e $HOME/quay-install ] && return 0
  ssh highside /mnt/high-side-data/mirror-registry install --initPassword discopass
}

cp -n configs/* scratch/

sudo cp scratch/bin/{oc*,kube*} /usr/local/bin/
sudo chmod +x /usr/local/bin/*

rsync -avP scratch/bin/{mirror-registry,*.tar,oc,openshift*,kube*} highside:/mnt/high-side-data/

install_quay

ssh highside sudo cp -v $HOME/quay-install/quay-rootCA/rootCA.pem /etc/pki/ca-trust/source/anchors/
ssh highside sudo update-ca-trust

scp highside:$HOME/quay-install/quay-rootCA/rootCA.pem /tmp/
sudo cp /tmp/rootCA.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

cp $HOME/pull-secret-example.json $XDG_RUNTIME_DIR/containers/auth.json
REGISTRY=$(ssh highside hostname):8443

podman login -u init -p discopass ${REGISTRY}

oc-mirror \
  -c scratch/isc-combo.yaml \
  --workspace file:///${PWD}/scratch/oc-mirror \
  docker://"${REGISTRY}" \
  --v2 \
  --authfile $XDG_RUNTIME_DIR/containers/auth.json

