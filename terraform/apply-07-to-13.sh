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

# Helm wait=false — pause until workloads are healthy before the next stack.
# wait_pods_ready <namespace> <label-selector> [timeout_seconds]
wait_pods_ready() {
  kubectl wait --for=condition=Ready pod -l "$2" -n "$1" --timeout="${3:-300}s"
}

# wait_rollout <namespace> <deployment-name> [timeout_seconds]
wait_rollout() {
  kubectl rollout status "deploy/$2" -n "$1" --timeout="${3:-300}s"
}

# ---------------------------------------------------------------------------
# 07_alb-controller
# Creates: IAM policy/role (IRSA) + AWS Load Balancer Controller Helm release
# Timed: ~22s terraform + ~21s until pods Ready
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-1: Create ALB Controller using Terraform"
echo "==============================="
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
echo
echo "==============================="
echo "STEP-2: Create ExternalDNS using Terraform"
echo "==============================="
cd "${ROOT}/08_external-dns"
terraform init
terraform apply --auto-approve
wait_rollout kube-system external-dns 120

# ---------------------------------------------------------------------------
# 09_argocd
# Creates: Argo CD Helm release in namespace argocd (UI via ALB Ingress)
# Timed: ~16s terraform + ~21s until server Ready
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-3: Create Argo CD using Terraform"
echo "==============================="
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
echo
echo "==============================="
echo "STEP-4: Create EBS CSI Driver using Terraform"
echo "==============================="
cd "${ROOT}/10_ebs-csi-driver"
terraform init
terraform apply --auto-approve
wait_pods_ready kube-system "app=ebs-csi-controller" 180

# ---------------------------------------------------------------------------
# 11_storage-class
# Creates: default StorageClass "ebs-storage-class" (ebs.csi.aws.com)
# Timed: ~2s terraform + ~1s verify
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-5: Create StorageClass using Terraform"
echo "==============================="
cd "${ROOT}/11_storage-class"
terraform init
terraform apply --auto-approve
kubectl get storageclass ebs-storage-class >/dev/null

# ---------------------------------------------------------------------------
# 12_metrics-server
# Creates: metrics-server Helm release (kubectl top / HPA CPU metrics)
# Timed: ~4s terraform + ~21s until metrics API answers
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-6: Create metrics-server using Terraform"
echo "==============================="
cd "${ROOT}/12_metrics-server"
terraform init
terraform apply --auto-approve
wait_rollout kube-system metrics-server 180
echo ">> waiting for metrics API"
kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=180s

# ---------------------------------------------------------------------------
# 13_kube-prometheus-stack
# Creates: Prometheus, Grafana, Alertmanager Helm release in namespace monitoring
# Timed: ~32s terraform + ~16s until Grafana Ready (Alertmanager needs Slack api_url)
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-7: Create kube-prometheus-stack using Terraform"
echo "==============================="
cd "${ROOT}/13_kube-prometheus-stack"
terraform init
terraform apply --auto-approve
wait_rollout monitoring my-kube-prometheus-stack-grafana 600
wait_pods_ready monitoring "app.kubernetes.io/name=grafana" 600

echo "Done: 07_alb-controller → 13_kube-prometheus-stack (each stack waited until Ready)."
