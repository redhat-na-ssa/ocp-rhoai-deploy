#!/bin/sh

# create ocp install
cat << EOF > /mnt/high-side-data/install-config.yaml
---
apiVersion: v1
metadata:
  name: disco
baseDomain: lab
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  replicas: 1
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: us-east-2
    subnets:
    - $(aws ec2 describe-subnets --filters "Name=tag:aws:cloudformation:logical-id,Values=*Private*" --query "Subnets[*].SubnetId" --output text)
publish: Internal
additionalTrustBundlePolicy: Always
EOF

# add ssh key to install
ssh-keygen -C "OpenShift Debug" -N "" -f /mnt/high-side-data/id_rsa
echo "sshKey: $(cat /mnt/high-side-data/id_rsa.pub)" | tee -a /mnt/high-side-data/install-config.yaml

# login to highside registry
REGISTRY=$(hostname):8443
podman login -u init -p discopass ${REGISTRY}

# add pull secret to install
echo "pullSecret: '$(jq -c . $XDG_RUNTIME_DIR/containers/auth.json)'" | tee -a /mnt/high-side-data/install-config.yaml

# add CA to install
cat << EOF >> /mnt/high-side-data/install-config.yaml
additionalTrustBundle: |
$(sed 's/^/  /' /home/lab-user/quay-install/quay-rootCA/rootCA.pem)
EOF

# setup mirror
echo "
imageDigestSources:
$(grep "mirrors:" -A 2 --no-group-separator /mnt/high-side-data/cluster-resources/idms-oc-mirror.yaml)
" | tee -a /mnt/high-side-data/install-config.yaml

# install ocp
install_openshift(){
  [ -e /mnt/high-side-data/install ] && return 0
  
  mkdir -p /mnt/high-side-data/install
  cp /mnt/high-side-data/install-config.yaml /mnt/high-side-data/install
  
  /mnt/high-side-data/openshift-install create manifests --dir /mnt/high-side-data/install
  
  cp -a /mnt/high-side-data/cluster-resources/*.yaml /mnt/high-side-data/install

  /mnt/high-side-data/openshift-install create cluster --dir /mnt/high-side-data/install
}

install_openshift
