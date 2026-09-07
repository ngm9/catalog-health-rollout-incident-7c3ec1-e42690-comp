#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if ! kubectl get --raw=/readyz >/dev/null 2>&1; then
  echo "Kubernetes API server is not available." >&2
  exit 1
fi

echo "Applying namespace..."
kubectl apply -f manifests/namespace.yaml

echo "Applying catalog configuration and workload..."
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml

echo "Current workload objects:"
kubectl get deployment,pods,service -n cartline-catalog -o wide || true

echo "Current Service backends:"
kubectl get endpoints,endpointslices -n cartline-catalog || true
