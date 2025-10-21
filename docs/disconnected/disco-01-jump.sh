#!/bin/sh

# get all the cli tools
scripts/bootstrap.sh

# adhoc for disconnected setup

# copy configs to scratch
cp -nr configs/* scratch/

# install cli tools
sudo cp scratch/bin/{oc*,kube*} /usr/local/bin/
sudo chmod +x /usr/local/bin/*

# install cli tools on highside
rsync -avP scratch/bin/{oc,openshift*,kube*} highside:/mnt/high-side-data/
rsync -avP scratch/bin/{mirror-registry,*.tar} highside:/mnt/high-side-data/quay/

install_quay(){
  ssh highside [ -e $HOME/quay-install ] && return 0
  ssh highside /mnt/high-side-data/quay/mirror-registry install --initPassword discopass
}

install_quay

# setup CA on highside
ssh highside sudo cp -v $HOME/quay-install/quay-rootCA/rootCA.pem /etc/pki/ca-trust/source/anchors/
ssh highside sudo update-ca-trust

# setup CA on jump
scp highside:$HOME/quay-install/quay-rootCA/rootCA.pem /tmp/
sudo cp /tmp/rootCA.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# setup registry login
[ -d $XDG_RUNTIME_DIR/containers ] || mkdir -p $XDG_RUNTIME_DIR/containers
cp $HOME/pull-secret-example.json $XDG_RUNTIME_DIR/containers/auth.json
REGISTRY=$(ssh highside hostname):8443

# login to highside registry
podman login -u init -p discopass ${REGISTRY}

# mirror all the images
mirror_images(){
  [ -e ${PWD}/scratch/oc-mirror/working-dir/cluster-resources ] && return 0

  oc-mirror \
    -c scratch/isc-combo.yaml \
    --workspace file:///${PWD}/scratch/oc-mirror \
    docker://"${REGISTRY}" \
    --v2 \
    --image-timeout 60m \
    --authfile ${XDG_RUNTIME_DIR}/containers/auth.json
}

mirror_images

# copy ocp install configs to highside
rsync -av ${PWD}/scratch/oc-mirror/working-dir/cluster-resources highside:/mnt/high-side-data/
rsync -av ${PWD}/scratch/catalogs highside:/mnt/high-side-data/

# copy script to highside
scp dump/*-high.sh highside:/mnt/high-side-data/
