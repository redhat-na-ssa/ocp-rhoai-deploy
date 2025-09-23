#!/bin/sh

# adhoc for disconnected setup

sudo cp scratch/bin/{oc*,kube*} /usr/local/bin/
sudo chmod +x /usr/local/bin/*

rsync -avP scratch/bin/{mirror-registry,*.tar,oc,openshift*,kube*} highside:/mnt/high-side-data/

