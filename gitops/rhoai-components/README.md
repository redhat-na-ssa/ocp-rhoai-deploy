## RHOAI Components

This directory contains Kustomize packages that configure and extend Red Hat OpenShift AI (RHOAI) at the cluster and project level. Each subfolder is an independently applicable component that you can apply with `oc apply -k`.

### Structure

- `rhoai-cluster-settings/`: Cluster-wide defaults and dashboard tweaks for RHOAI
- `rhoai-configure-logging/`: Adjust logging settings on the DataScienceCluster
- `rhoai-enable-features/`: Enable/disable optional RHOAI features via `ODHDashboardConfig`
- `rhoai-gpu-timeslicing/`: NVIDIA GPU Operator time-slicing configuration and related resources
- `rhoai-hw-profiles/`: GPU hardware profiles and workbench (notebook) manifests
- `rhoai-resource-quota/`: Sample namespaces and quotas/limits for project-level governance
- `rhoai-groups/`: rhods-users group

### Prerequisites

- Logged into a cluster with `oc` and sufficient privileges (cluster-admin recommended)
- Core operators installed and healthy, e.g.:
  - RHOAI Operator and its dependent components (serverless and servicemesh 2)
  - Node Feature Discovery (for GPU/node labeling use cases)
  - NVIDIA GPU Operator (if using GPU/timeslicing)

### Apply a component

Apply any component independently:

```bash
until oc apply -k gitops/rhoai-components/rhoai-cluster-settings; do : ; done
until oc apply -k gitops/rhoai-components/rhoai-enable-features; do : ; done
until oc apply -k gitops/rhoai-components/rhoai-configure-logging; do : ; done
until oc apply -k gitops/rhoai-components/rhoai-gpu-timeslicing; do : ; done
until oc apply -k gitops/rhoai-components/rhoai-hw-profiles; do : ; done
until oc apply -k gitops/rhoai-components/rhoai-resource-quota; do : ; done
until oc apply -k gitops/rhoai-components/rhoai-gpu-dashboard; do : ; done
until oc apply -k gitops/rhoai-components/rhoai-vllm-monitoring; do : ; done
```

### Removal

To remove a component, delete with Kustomize or apply the relevant uninstall overlay if provided by the component:

```bash
oc delete -k gitops/rhoai-components/rhoai-hw-profiles
```

Use caution when deleting cluster-wide resources.
