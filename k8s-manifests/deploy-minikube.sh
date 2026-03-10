#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${NAMESPACE:-default}"
APP_HOSTNAME="${APP_HOSTNAME:-wisecow.local}"
TLS_DIR="${TLS_DIR:-/tmp/wisecow-tls}"
MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-minikube}"
MINIKUBE_START="${MINIKUBE_START:-auto}" # auto|true|false
MINIKUBE_ARGS="${MINIKUBE_ARGS:-}"      # e.g. "--driver=docker --memory=2048mb --cpus=2"

start_minikube() {
  local profile="$1"
  if [ "$MINIKUBE_START" = "false" ] || [ "$MINIKUBE_START" = "0" ]; then
    echo "Skipping Minikube start (MINIKUBE_START=false). Using profile: $profile"
    return 0
  fi

  if [ "$MINIKUBE_START" = "auto" ]; then
    status="$(minikube -p "$profile" status --format='{{.Host}}' 2>/dev/null || true)"
    if [ "$status" = "Running" ]; then
      echo "Minikube profile '$profile' already running. Skipping start."
      return 0
    fi
  fi

  echo "Starting Minikube profile '$profile'..."
  minikube -p "$profile" start $MINIKUBE_ARGS
}

start_minikube "$MINIKUBE_PROFILE"

echo "Setting kubectl context to '$MINIKUBE_PROFILE'..."
kubectl config use-context "$MINIKUBE_PROFILE" >/dev/null

echo "Enabling ingress addon..."
minikube -p "$MINIKUBE_PROFILE" addons enable ingress

INGRESS_NS="ingress-nginx"
if ! kubectl get ns "$INGRESS_NS" >/dev/null 2>&1; then
  INGRESS_NS="kube-system"
fi

if kubectl -n "$INGRESS_NS" get deployment ingress-nginx-controller >/dev/null 2>&1; then
  echo "Waiting for ingress controller to be ready..."
  kubectl -n "$INGRESS_NS" rollout status deployment/ingress-nginx-controller --timeout=180s
else
  echo "Warning: ingress-nginx-controller deployment not found in $INGRESS_NS. Ingress may not be ready yet."
fi

wait_for_admission() {
  local ns="$1"
  local tries="${2:-30}"
  echo "Waiting for ingress admission endpoint..."
  for i in $(seq 1 "$tries"); do
    endpoints="$(kubectl -n "$ns" get endpoints ingress-nginx-controller-admission -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)"
    if [ -n "$endpoints" ]; then
      echo "Admission endpoint ready: $endpoints"
      return 0
    fi
    sleep 5
  done
  echo "Warning: admission endpoint not ready after $tries attempts."
  return 1
}
wait_for_admission "$INGRESS_NS" 24 || true

echo "Applying deployment and service..."
kubectl apply -n "$NAMESPACE" -f "$SCRIPT_DIR/deployment.yaml"
kubectl apply -n "$NAMESPACE" -f "$SCRIPT_DIR/service.yaml"

echo "Creating self-signed TLS cert for $APP_HOSTNAME..."
mkdir -p "$TLS_DIR"
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout "$TLS_DIR/tls.key" \
  -out "$TLS_DIR/tls.crt" \
  -subj "/CN=$APP_HOSTNAME/O=wisecow"

kubectl create secret tls wisecow-tls \
  --cert="$TLS_DIR/tls.crt" \
  --key="$TLS_DIR/tls.key" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Applying ingress..."
if ! kubectl apply -n "$NAMESPACE" -f "$SCRIPT_DIR/ingress.yaml"; then
  echo "Ingress apply failed. Restarting ingress controller and retrying..."
  kubectl -n "$INGRESS_NS" rollout restart deployment/ingress-nginx-controller || true
  kubectl -n "$INGRESS_NS" rollout status deployment/ingress-nginx-controller --timeout=180s || true
  wait_for_admission "$INGRESS_NS" 24 || true
  kubectl apply -n "$NAMESPACE" -f "$SCRIPT_DIR/ingress.yaml"
fi

MINIKUBE_IP="$(minikube -p "$MINIKUBE_PROFILE" ip)"
echo "Minikube IP: $MINIKUBE_IP"
echo "Map host locally with:"
echo "  sudo sh -c 'echo \"$MINIKUBE_IP $APP_HOSTNAME\" >> /etc/hosts'"

echo "Waiting for deployment rollout..."
kubectl rollout status -n "$NAMESPACE" deployment/wisecow-app-deployment

echo "Test HTTPS with:"
echo "  curl -k https://$APP_HOSTNAME"
