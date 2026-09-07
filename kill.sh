#!/usr/bin/env bash
set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Starting Kubernetes/minikube cleanup..."
if command -v minikube >/dev/null 2>&1; then
  echo "Current minikube status:"
  minikube status || true
else
  echo "minikube is not installed; continuing cleanup."
fi

echo "Deleting all minikube profiles and cached state..."
minikube delete --all --purge || true

echo "Removing task-generated local artifacts..."
rm -rf .task-state logs tmp || true

echo "Pruning optional Docker containers..."
docker container prune -f || true

echo "Pruning optional Docker networks..."
docker network prune -f || true

echo "Pruning optional Docker volumes..."
docker volume prune -f || true

echo "Cleanup completed successfully!"
exit 0
