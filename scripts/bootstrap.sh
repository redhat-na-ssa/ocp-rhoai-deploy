#!/bin/bash
# set -e
set -x

# shellcheck disable=SC2034

################# standard init #################

# 8 seconds is usually enough time for the average user to realize they foobar
export SLEEP_SECONDS=8

ORANGE='\033[0;33m'
NC='\033[0m' # No Color

check_shell(){
  [ -n "$BASH_VERSION" ] && return
  echo -e "${ORANGE}WARNING: These scripts are ONLY tested in a bash shell${NC}"
  sleep "${SLEEP_SECONDS:-8}"
}

check_git_root(){
  if [ -d .git ] && [ -d scripts ]; then
    GIT_ROOT=$(pwd)
    export GIT_ROOT
    echo "GIT_ROOT: ${GIT_ROOT}"
  else
    echo "Please run this script from the root of the git repo"
    exit
  fi
}

check_script_path(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo "SCRIPT_DIR: ${SCRIPT_DIR}"
}

check_shell
check_git_root
check_script_path

################# standard init #################

# shellcheck source=/dev/null
. "${SCRIPT_DIR}/functions.sh"

is_sourced && return

bin_check oc
bin_check oc-mirror
bin_check openshift-install
bin_check mirror-registry
