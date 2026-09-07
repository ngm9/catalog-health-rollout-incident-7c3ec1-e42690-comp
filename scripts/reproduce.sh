#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

NAMESPACE="cartline-catalog"
CLIENT_NAME="catalog-reproduction-$RANDOM"
cleanup() {
  kubectl delete pod "$CLIENT_NAME" -n "$NAMESPACE" --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

if ! kubectl get service catalog-api -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Catalog Service is not present." >&2
  exit 1
fi

BACKENDS="$(kubectl get endpoints catalog-api -n "$NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)"
if [[ -z "$BACKENDS" ]]; then
  echo "Incident reproduced: the catalog Service has no ready backends." >&2
  kubectl get pods,endpoints -n "$NAMESPACE" -o wide || true
  exit 1
fi

kubectl run "$CLIENT_NAME" \
  -n "$NAMESPACE" \
  --image=cartline-catalog:local \
  --image-pull-policy=IfNotPresent \
  --restart=Never \
  --command -- python -c '
import json
import sys
import urllib.request

try:
    with urllib.request.urlopen("http://catalog-api/v1/catalog/summary", timeout=5) as response:
        summary_status = response.status
        summary = json.load(response)
    with urllib.request.urlopen("http://catalog-api/health/ready", timeout=5) as response:
        health_status = response.status
        health = json.load(response)
except Exception as exc:
    print(f"service request failed: {exc}", file=sys.stderr)
    raise SystemExit(1)

valid = (
    summary_status == 200
    and summary.get("status") == "available"
    and summary.get("market") == "eu-west"
    and health_status == 200
    and health.get("status") == "ready"
)
print(json.dumps({"summary": summary, "health": health}, sort_keys=True))
raise SystemExit(0 if valid else 1)
' >/dev/null

if ! kubectl wait --for=jsonpath='{.status.phase}'=Succeeded "pod/$CLIENT_NAME" -n "$NAMESPACE" --timeout=20s >/dev/null 2>&1; then
  echo "Incident reproduced: the in-cluster Service request did not meet the API contract." >&2
  kubectl logs "$CLIENT_NAME" -n "$NAMESPACE" || true
  kubectl get pod "$CLIENT_NAME" -n "$NAMESPACE" -o wide || true
  exit 1
fi

kubectl logs "$CLIENT_NAME" -n "$NAMESPACE"
echo "Catalog Service and API contract are healthy."
