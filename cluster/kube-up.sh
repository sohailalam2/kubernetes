#!/bin/bash

# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Bring up a Kubernetes cluster.
#
# If the full release name (gs://<bucket>/<release>) is passed in then we take
# that directly.  If not then we assume we are doing development stuff and take
# the defaults in the release config.

set -o errexit
set -o nounset
set -o pipefail

KUBE_ROOT=$(dirname "${BASH_SOURCE}")/..
source "${KUBE_ROOT}/cluster/kube-env.sh"
source "${KUBE_ROOT}/cluster/${KUBERNETES_PROVIDER}/util.sh"

echo "Starting cluster using provider: $KUBERNETES_PROVIDER" >&2

echo "... calling verify-prereqs" >&2
verify-prereqs

echo "... calling kube-up" >&2
kube-up

echo "... calling validate-cluster" >&2
"${KUBE_ROOT}/cluster/validate-cluster.sh"

echo "... calling setup-monitoring" >&2
setup-monitoring

if [[ "${ENABLE_CLUSTER_DNS}" == "true" ]]; then
  echo ".. setting up cluster DNS"
  sed -e "s/{DNS_DOMAIN}/$DNS_DOMAIN/g" \
      -e "s/{DNS_REPLICAS}/$DNS_REPLICAS/g" \
      "${KUBE_ROOT}/cluster/addons/dns/skydns-rc.yaml.in" \
      | "${KUBE_ROOT}/cluster/kubectl.sh" create -f -

  sed -e "s/{DNS_SERVER_IP}/$DNS_SERVER_IP/g" \
      "${KUBE_ROOT}/cluster/addons/dns/skydns-svc.yaml.in" \
      | "${KUBE_ROOT}/cluster/kubectl.sh" create -f -
fi

echo "Done" >&2
