#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

for required in Dockerfile requirements.txt manifests/namespace.yaml scripts/apply.sh; do
  if [[ ! -f "$required" ]]; then
    echo "Required repository file is missing: $required" >&2
    exit 1
  fi
done

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but is not available." >&2
  exit 1
fi

if ! command -v minikube >/dev/null 2>&1; then
  echo "Installing minikube..."
  curl https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o /usr/local/bin/minikube && chmod +x /usr/local/bin/minikube
fi

echo "Starting the single-node Kubernetes cluster..."
minikube start --driver=docker --force --cpus=2 --memory=1800mb --kubernetes-version=v1.31.14 --wait=apiserver

echo "Waiting for the API server and node object..."
for attempt in $(seq 1 30); do
  if kubectl get nodes >/dev/null 2>&1 && kubectl get --raw=/readyz >/dev/null 2>&1; then
    break
  fi
  if [[ "$attempt" -eq 30 ]]; then
    echo "The Kubernetes API server did not become available." >&2
    exit 1
  fi
  sleep 1
done

kubectl get nodes

echo "Building the catalog image inside minikube..."
minikube image build -t cartline-catalog:local .

echo "Applying the incident workload..."
bash scripts/apply.sh

echo "Starter environment is deployed. The workload may remain unhealthy by design."
echo "Use ./scripts/status.sh for evidence and ./scripts/reproduce.sh to reproduce the incident."

# --- Kubernetes Dashboard tab (platform port 8001) --------------------------
# Served at the ROOT of :8001 via port-forward, because the assessment UI builds
# a tab URL as https://<port>-<sandbox>.e2b.app and cannot append a path.
# Detached so it costs this script's boot budget nothing; the tab becomes live
# roughly 40s after the environment starts. The loop re-establishes the forward
# if the dashboard pod restarts.
nohup setsid bash -c '
  minikube addons enable dashboard >/dev/null 2>&1
  kubectl -n kubernetes-dashboard rollout status deploy/kubernetes-dashboard --timeout=300s >/dev/null 2>&1
  while true; do
    kubectl port-forward -n kubernetes-dashboard --address 0.0.0.0 \
      svc/kubernetes-dashboard 8001:80 >/dev/null 2>&1
    sleep 2
  done
' >/tmp/dashboard.log 2>&1 &
