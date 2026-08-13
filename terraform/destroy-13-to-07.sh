#!/usr/bin/env bash
# Destroy bastion stacks 13_kube-prometheus-stack → 07_alb-controller.
# Run on the bastion (needs kubectl / Helm access to the private EKS API).
# Order is the reverse of apply-07-to-13.sh.
#
# Before running: delete the easyshop Argo CD app / namespace if present
# (Ingresses/ALBs left behind can block later destroys).
#
# After each destroy, wait until related workloads/namespaces are gone so the
# next destroy is not racing ALB Ingress finalizers.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

wait_ns_gone() {
  local ns="$1" timeout="${2:-600}"
  echo ">> waiting for namespace ${ns} to disappear (timeout ${timeout}s)"
  local i=0
  while kubectl get ns "${ns}" >/dev/null 2>&1; do
    if [ "$i" -ge "$timeout" ]; then
      echo "WARNING: namespace ${ns} still present after ${timeout}s (check Ingress finalizers)"
      return 0
    fi
    sleep 5
    i=$((i + 5))
  done
  echo ">> namespace ${ns} is gone"
}

wait_deploy_gone() {
  local ns="$1" name="$2" timeout="${3:-300}"
  echo ">> waiting for deploy/${name} gone from ${ns}"
  local i=0
  while kubectl get deploy "${name}" -n "${ns}" >/dev/null 2>&1; do
    if [ "$i" -ge "$timeout" ]; then
      echo "WARNING: deploy/${name} still present after ${timeout}s"
      return 0
    fi
    sleep 5
    i=$((i + 5))
  done
}

# ---------------------------------------------------------------------------
# 13_kube-prometheus-stack
# Destroys: Prometheus, Grafana, Alertmanager Helm release (namespace monitoring)
# ---------------------------------------------------------------------------
cd "${ROOT}/13_kube-prometheus-stack"
terraform init
terraform destroy --auto-approve
wait_ns_gone monitoring 900

# ---------------------------------------------------------------------------
# 12_metrics-server
# Destroys: metrics-server Helm release in kube-system
# ---------------------------------------------------------------------------
cd "${ROOT}/12_metrics-server"
terraform init
terraform destroy --auto-approve
wait_deploy_gone kube-system metrics-server 300

# ---------------------------------------------------------------------------
# 11_storage-class
# Destroys: default StorageClass "ebs-storage-class"
# ---------------------------------------------------------------------------
cd "${ROOT}/11_storage-class"
terraform init
terraform destroy --auto-approve
until ! kubectl get storageclass ebs-storage-class >/dev/null 2>&1; do sleep 2; done

# ---------------------------------------------------------------------------
# 10_ebs-csi-driver
# Destroys: EBS CSI driver Helm release + IRSA role
# ---------------------------------------------------------------------------
cd "${ROOT}/10_ebs-csi-driver"
terraform init
terraform destroy --auto-approve
# controller pods should leave kube-system
sleep 10

# ---------------------------------------------------------------------------
# 09_argocd
# Destroys: Argo CD Helm release (namespace argocd)
# ---------------------------------------------------------------------------
cd "${ROOT}/09_argocd"
terraform init
terraform destroy --auto-approve
wait_ns_gone argocd 900

# ---------------------------------------------------------------------------
# 08_external-dns
# Destroys: ExternalDNS Helm release + IRSA policy/role
# ---------------------------------------------------------------------------
cd "${ROOT}/08_external-dns"
terraform init
terraform destroy --auto-approve
wait_deploy_gone kube-system external-dns 300

# ---------------------------------------------------------------------------
# 07_alb-controller
# Destroys: AWS Load Balancer Controller Helm release + IRSA policy/role
# ---------------------------------------------------------------------------
cd "${ROOT}/07_alb-controller"
terraform init
terraform destroy --auto-approve
sleep 15

echo "Done: destroyed 13_kube-prometheus-stack → 07_alb-controller."
