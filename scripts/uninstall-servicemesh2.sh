#!/bin/bash

set -e  # Exit on any error

LOG_DIR="logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/install-component_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log to file
log_to_file() {
    local message="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# Log to both console and file with color
log_both() {
    local message="$1"
    echo -e "$message"
    # Strip color codes for log file
    echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

# Logging function
log() {
    log_both "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    log_both "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

warning() {
    log_both "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

error() {
    log_both "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

# Check DataScienceCluster kserve configuration
check_datasciencecluster_kserve() {
    log "Checking DataScienceCluster kserve configuration..."
    
    # Get the first DataScienceCluster instance
    local dsc_name=$(oc get datasciencecluster -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$dsc_name" ]; then
        error "No DataScienceCluster found"
        return 1
    fi
    
    log "Found DataScienceCluster: $dsc_name"
    
    local check_passed=true
    
    # Get the managementState value
    local management_state=$(oc get datasciencecluster "$dsc_name" -o jsonpath='{.spec.components.kserve.serving.managementState}' 2>/dev/null)
  
    # Check managementState
    if [ "$management_state" = "Removed" ]; then
        success "spec.components.kserve.serving.managementState = Removed ✓"
    else
        error "spec.components.kserve.serving.managementState = '$management_state' (expected: Removed)"
        check_passed=false
    fi

    # Get the defaultDeploymentMode value
    local deployment_mode=$(oc get datasciencecluster "$dsc_name" -o jsonpath='{.spec.components.kserve.defaultDeploymentMode}' 2>/dev/null)

    # Check defaultDeploymentMode
    if [ "$deployment_mode" = "RawDeployment" ]; then
        success "spec.components.kserve.defaultDeploymentMode = RawDeployment ✓"
    else
        error "spec.components.kserve.defaultDeploymentMode = '$deployment_mode' (expected: RawDeployment)"
        check_passed=false
    fi
    
    if [ "$check_passed" = true ]; then
        success "DataScienceCluster kserve configuration is correct"
        return 0
    else
        error "DataScienceCluster kserve configuration is incorrect"
        return 1
    fi
}

# Check DSCInitialization serviceMesh configuration
check_dscinitialization_servicemesh() {
    log "Checking DSCInitialization serviceMesh configuration..."
    
    # Check if the DSCInitialization object exists
    if ! oc get dscinitialization default-dsci &> /dev/null; then
        error "DSCInitialization 'default-dsci' not found"
        return 1
    fi
    
    # Get the managementState value
    local management_state=$(oc get dscinitialization default-dsci -o jsonpath='{.spec.serviceMesh.managementState}' 2>/dev/null)
    
    # Check managementState
    if [ "$management_state" = "Removed" ]; then
        success "spec.serviceMesh.managementState = Removed ✓"
        success "DSCInitialization serviceMesh configuration is correct"
        return 0
    else
        error "spec.serviceMesh.managementState = '$management_state' (expected: Removed)"
        error "DSCInitialization serviceMesh configuration is incorrect"
        return 1
    fi
}

# Check that no Service Mesh objects exist
check_no_servicemesh_objects() {
    log "Checking that no Service Mesh objects exist..."
    
    # List of resource types to check (easily extendable)
    local resource_types=(
        "exportedservicesets.federation.maistra.io"
        "importedservicesets.federation.maistra.io"
        "servicemeshcontrolplanes.maistra.io"
        "servicemeshmemberrolls.maistra.io"
        "servicemeshmembers.maistra.io"
        "servicemeshpeers.federation.maistra.io"
        "servicemeshpolicies.authentication.maistra.io"
        "servicemeshrbacconfigs.rbac.maistra.io"
    )
    
    local check_passed=true
    
    # Loop through each resource type and check for existence
    for resource_type in "${resource_types[@]}"; do
        # Get a friendly name for the resource type (remove .maistra.io suffix)
        local friendly_name="${resource_type%.maistra.io}"
        
        # Count the number of resources
        local count=$(oc get "$resource_type" --all-namespaces -o json 2>/dev/null | jq -r '.items | length' 2>/dev/null)
        
        # Ensure count is a valid integer (default to 0 if empty or invalid)
        if [ -z "$count" ] || ! [[ "$count" =~ ^[0-9]+$ ]]; then
            count=0
        fi
        
        if [ "$count" -eq 0 ]; then
            success "No ${friendly_name} found ✓"
        else
            error "Found $count ${friendly_name} (expected: 0)"
            
            # List each found resource with namespace and name
            oc get "$resource_type" --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers 2>/dev/null | while read -r line; do
                error "  - $line"
            done
            
            check_passed=false
        fi
    done
    
    # Final status message
    if [ "$check_passed" = true ]; then
        success "No Service Mesh objects found - cluster is clean"
        return 0
    else
        error "Service Mesh objects still exist in the cluster"
        return 1
    fi
}

# Delete Service Mesh CRDs
delete_servicemesh_crds() {
    log "Deleting Service Mesh CRDs..."
    
    # List of CRDs to delete (easily extendable)
    local crds=(
        "exportedservicesets.federation.maistra.io"
        "importedservicesets.federation.maistra.io"
        "servicemeshcontrolplanes.maistra.io"
        "servicemeshmemberrolls.maistra.io"
        "servicemeshmembers.maistra.io"
        "servicemeshpeers.federation.maistra.io"
        "servicemeshpolicies.authentication.maistra.io"
        "servicemeshrbacconfigs.rbac.maistra.io"
    )
    
    local deletion_failed=false
    
    # Loop through each CRD and delete it
    for crd in "${crds[@]}"; do
        # Check if CRD exists
        if oc get crd "$crd" &> /dev/null; then
            log "Deleting CRD: $crd"
            
            if oc delete crd "$crd" --timeout=60s >> "$LOG_FILE" 2>&1; then
                success "Deleted CRD: $crd ✓"
            else
                error "Failed to delete CRD: $crd"
                deletion_failed=true
            fi
        else
            warning "CRD not found (already deleted?): $crd"
        fi
    done
    
    # Final status message
    if [ "$deletion_failed" = false ]; then
        success "All Service Mesh CRDs deleted successfully"
        return 0
    else
        error "Some Service Mesh CRDs failed to delete"
        return 1
    fi
}

# Delete Service Mesh Operator Subscription
delete_servicemesh_subscription() {
    log "Deleting Service Mesh Operator Subscription..."
    
    local subscription_name="servicemeshoperator"
    local namespace="openshift-operators"
    
    # Check if the Subscription exists
    if oc get subscription "$subscription_name" -n "$namespace" &> /dev/null; then
        log "Found Subscription: $subscription_name in namespace: $namespace"
        
        if oc delete subscription "$subscription_name" -n "$namespace" --timeout=60s >> "$LOG_FILE" 2>&1; then
            success "Deleted Subscription: $subscription_name ✓"
            return 0
        else
            error "Failed to delete Subscription: $subscription_name"
            return 1
        fi
    else
        warning "Subscription '$subscription_name' not found in namespace '$namespace' (already deleted?)"
        return 0
    fi
}

main() {
    log "Starting Service Mesh 2 Uninstallation"
    log "=================================================="
    check_datasciencecluster_kserve
    check_dscinitialization_servicemesh
    check_no_servicemesh_objects
    
    # Ask user if they want to delete the Service Mesh subscription
    echo ""
    echo -e "${YELLOW}Do you want to delete the Service Mesh operator subscription?${NC}"
    echo -e "${YELLOW}This will remove the servicemeshoperator subscription from openshift-operators namespace.${NC}"
    read -p "Continue? (yes/no): " -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]([Ee][Ss])?$ ]]; then
        delete_servicemesh_subscription
    else
        warning "Skipping Service Mesh subscription deletion"
    fi

    # Ask user if they want to delete the Service Mesh CRDs
    echo ""
    echo -e "${YELLOW}Do you want to delete the Service Mesh CRDs?${NC}"
    read -p "Continue? (yes/no): " -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]([Ee][Ss])?$ ]]; then
        delete_servicemesh_crds
    else
        warning "Skipping Service Mesh CRDs deletion"
    fi
    
}

main "$@"
