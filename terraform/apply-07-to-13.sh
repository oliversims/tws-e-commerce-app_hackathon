#!/usr/bin/env bash
# Apply bastion stacks 07_alb-controller → 13_kube-prometheus-stack.
# Prerequisites: 01–04 + 06 applied, SSH on bastion, kubeconfig ready.
# Run on the bastion (needs kubectl / Helm access to the private EKS API).
#
# Before 13: set Slack webhook api_url in 13_kube-prometheus-stack/values.yaml
# (bastion only — do not commit). Empty api_url prevents Alertmanager from starting.
#
# Each stack: terraform apply, then wait until workloads are Ready before the next
# stack (Helm uses wait=false, so TF alone finishes before pods are healthy).
# Timed cold-create (approx TF + ready): 07~43s 08~27s 09~37s 10~27s 11~3s 12~25s 13~48s

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

wait_pods_ready() {
  local ns="$1" selector="$2" timeout="${3:-300}"
  echo ">> waiting for pods Ready (${selector}) in ${ns} (timeout ${timeout}s)"
  kubectl wait --for=condition=Ready pod -l "${selector}" -n "${ns}" --timeout="${timeout}s"
}

wait_rollout() {
  local ns="$1" deploy="$2" timeout="${3:-300}"
  echo ">> waiting for deploy/${deploy} rollout in ${ns} (timeout ${timeout}s)"
  kubectl rollout status "deploy/${deploy}" -n "${ns}" --timeout="${timeout}s"
}

# ---------------------------------------------------------------------------
# 07_alb-controller
# Creates: IAM policy/role (IRSA) + AWS Load Balancer Controller Helm release
# Timed: ~22s terraform + ~21s until pods Ready
# ---------------------------------------------------------------------------
cd "${ROOT}/07_alb-controller"
terraform init
terraform apply --auto-approve
wait_pods_ready kube-system "app.kubernetes.io/name=aws-load-balancer-controller" 180
kubectl get ingressclass alb >/dev/null

# ---------------------------------------------------------------------------
# 08_external-dns
# Creates: IAM policy/role (IRSA) + ExternalDNS Helm release (Route 53 records)
# Timed: ~17s terraform + ~10s until rollout
# ---------------------------------------------------------------------------
cd "${ROOT}/08_external-dns"
terraform init
terraform apply --auto-approve
wait_rollout kube-system external-dns 120

# ---------------------------------------------------------------------------
# 09_argocd
# Creates: Argo CD Helm release in namespace argocd (UI via ALB Ingress)
# Timed: ~16s terraform + ~21s until server Ready
# ---------------------------------------------------------------------------
cd "${ROOT}/09_argocd"
terraform init
terraform apply --auto-approve
wait_rollout argocd argocd-server 300
wait_pods_ready argocd "app.kubernetes.io/name=argocd-server" 300

# ---------------------------------------------------------------------------
# 10_ebs-csi-driver
# Creates: IRSA role + AWS EBS CSI driver Helm release (for PersistentVolumes)
# Timed: ~15s terraform + ~12s until pods Ready
# ---------------------------------------------------------------------------
cd "${ROOT}/10_ebs-csi-driver"
terraform init
terraform apply --auto-approve
wait_pods_ready kube-system "app=ebs-csi-controller" 180

# ---------------------------------------------------------------------------
# 11_storage-class
# Creates: default StorageClass "ebs-storage-class" (ebs.csi.aws.com)
# Timed: ~2s terraform + ~1s verify
# ---------------------------------------------------------------------------
cd "${ROOT}/11_storage-class"
terraform init
terraform apply --auto-approve
kubectl get storageclass ebs-storage-class >/dev/null

# ---------------------------------------------------------------------------
# 12_metrics-server
# Creates: metrics-server Helm release (kubectl top / HPA CPU metrics)
# Timed: ~4s terraform + ~21s until metrics API answers
# ---------------------------------------------------------------------------
cd "${ROOT}/12_metrics-server"
terraform init
terraform apply --auto-approve
wait_rollout kube-system metrics-server 180
echo ">> waiting for metrics API"
for _ in $(seq 1 36); do
  if kubectl top nodes >/dev/null 2>&1; then
    break
  fi
  sleep 5
done
kubectl top nodes >/dev/null

# ---------------------------------------------------------------------------
# 13_kube-prometheus-stack
# Creates: Prometheus, Grafana, Alertmanager Helm release in namespace monitoring
# Timed: ~32s terraform + ~16s until Grafana Ready (Alertmanager needs Slack api_url)
# ---------------------------------------------------------------------------
cd "${ROOT}/13_kube-prometheus-stack"
terraform init
terraform apply --auto-approve
wait_rollout monitoring my-kube-prometheus-stack-grafana 600
wait_pods_ready monitoring "app.kubernetes.io/name=grafana" 600

echo "Done: 07_alb-controller → 13_kube-prometheus-stack (each stack waited until Ready)."
