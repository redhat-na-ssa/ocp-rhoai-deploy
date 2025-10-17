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
    - subnet-02e59fc9c2e36d590
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

# setup mirrorsets
# cat << EOF >> /mnt/high-side-data/install-config.yaml
# imageDigestSources:
# $(grep "mirrors:" -A 2 --no-group-separator cluster-resources/idms-oc-mirror.yaml)
# EOF

# install ocp
# /mnt/high-side-data/openshift-install create cluster --dir /mnt/high-side-data/ocp
