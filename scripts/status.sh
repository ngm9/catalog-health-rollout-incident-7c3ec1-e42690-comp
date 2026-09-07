#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

NAMESPACE="cartline-catalog"

echo "=== Workload status ==="
kubectl get deployment,replicaset,pods,service -n "$NAMESPACE" -o wide || true

echo
echo "=== Backend discovery ==="
kubectl get endpoints,endpointslices -n "$NAMESPACE" -o wide || true

echo
echo "=== Recent events ==="
kubectl get events -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -n 20 || true

echo
echo "=== Recent application logs ==="
kubectl logs -n "$NAMESPACE" deployment/catalog-api --tail=40 --all-containers=true || true
