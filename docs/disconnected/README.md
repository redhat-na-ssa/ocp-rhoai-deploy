# OpenShift Offline RHOAI install

## Prereqs

Red Hat Demo System

[OpenShift Disconnected Workshop](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.ocp4-disconnected.prod&utm_source=webapp&utm_medium=share-link)

## Greased Path

[disco-01-jump.sh](disco-01-jump.sh)

```sh
# run on jump host
docs/disconnected/disco-01-jump.sh

# run on high side
# ssh highside
docs/disconnected/disco-02-high.sh
```

## General Info

`oc-mirror` config for:

- [OpenShift 4.18](configs/isc-ocp-4.18.yaml)
- [OpenShift AI 2.22](configs/isc-rhoai-2.22.yaml)

List of images to mirror for:

- [OpenShift 4.18 - Images](mapping-ocp-4.18.txt)
- [OpenShift AI 2.22 - Images](mapping-rhoai-2.22.txt)
