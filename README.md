# OpenShift AI Deployment

## Notes for offline OCP + RHOAI install

See [README](docs/disconnected/README.md)

Setup OCP web terminal

```sh
# apply enhanced web terminal
oc apply -k https://github.com/redhat-na-ssa/ocp-rhoai-deploy/demo/web-terminal

# delete old terminal-tooling
$(wtoctl | grep delete)
```

Setup worker node in AWS

```sh
ocp_machineset_scale 1
ocp_control_nodes_not_schedulable
oc apply -k ../demo_ops/components/cluster-configs/autoscale/overlays/default
```

Setup GPU node in AWS

```sh
# setup gpu node
ocp_aws_machineset_create_gpu
ocp_machineset_scale 1
```

Setup Mig profile on node

See [Nvidia Docs - MIG](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html)

```sh
# patch gpu cluster policy
patch clusterpolicies.nvidia.com/cluster-policy \
  --type='json' \
  -p='[{"op":"replace", "path":"/spec/mig/strategy", "value":"single"}]'

# get mig profiles
oc -n nvidia-gpu-operator \
  describe cm default-mig-parted-config

# label a node with a mig profile
oc label nodes \
  <node-name> \
  nvidia.com/mig.config=all-1g.10gb --overwrite
```
