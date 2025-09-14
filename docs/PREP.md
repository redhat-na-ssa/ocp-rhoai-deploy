# Notes for offline RHOAI install

## RHOAI Offline Install

- [RHOAI Install - Mirroring Images](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.23/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#mirroring-images-to-a-private-registry-for-a-disconnected-installation_install)
- [RHOAI Disconnected](https://github.com/red-hat-data-services/rhoai-disconnected-install-helper)

## `oc-mirror`

- https://github.com/openshift/oc-mirror
- https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest

The following can create a `mapping.txt` file that can be used with `skopeo` to copy the images. This is **not** recommended - just notes of an insane mind.

Download `oc-mirror`

```sh
OPENSHIFT_CLIENTS_URL=https://mirror.openshift.com/pub/openshift-v4/x86_64/clients
BIN_PATH=${BIN_PATH:-scratch/bin}
[ -d "${BIN_PATH}" ] || mkdir -p "${BIN_PATH}"

download_oc-mirror(){
  BIN_VERSION=latest
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/ocp/${BIN_VERSION}/oc-mirror.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
  chmod +x "${BIN_PATH}/oc-mirror"
}

download_oc-mirror
```

Create `isc.yaml` - edit the copy for your needs

```sh
[ -d scratch ] || mkdir scratch
cp dump/isc.yaml scratch/

# vim scratch/isc.yaml
```

Create `mapping.txt`

```sh
REGISTRY=registry:5000

oc-mirror \
  -c scratch/isc.yaml \
  --workspace file:///${PWD}/scratch/oc-mirror \
  docker://"${REGISTRY}" \
  --v2 \
  --dry-run
```

Create `images.txt` - a list of images to copy

```sh
DATE=$(date +%Y-%m-%d)
sed '
  s@^docker://@@g
  s@=docker://'"${REGISTRY}"'.*@@g
  /localhost/d' \
    scratch/oc-mirror/working-dir/dry-run/mapping.txt \
    > scratch/images-"${DATE}".txt
```
