#!/usr/bin/env bash
# Apply bastion stacks 07_alb-controller → 13_kube-prometheus-stack.
# Prerequisites: 01–04 + 06 applied, SSH on bastion, kubeconfig ready.
# Run on the bastion (needs kubectl / Helm access to the private EKS API).
#
# Before 13: set Slack webhook api_url in 13_kube-prometheus-stack/values.yaml
# (bastion only — do not commit). Empty api_url prevents Alertmanager from starting.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 07_alb-controller
# Creates: IAM policy/role (IRSA) + AWS Load Balancer Controller Helm release
# ---------------------------------------------------------------------------
cd "${ROOT}/07_alb-controller"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 08_external-dns
# Creates: IAM policy/role (IRSA) + ExternalDNS Helm release (Route 53 records)
# ---------------------------------------------------------------------------
cd "${ROOT}/08_external-dns"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 09_argocd
# Creates: Argo CD Helm release in namespace argocd (UI via ALB Ingress)
# ---------------------------------------------------------------------------
cd "${ROOT}/09_argocd"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 10_ebs-csi-driver
# Creates: IRSA role + AWS EBS CSI driver Helm release (for PersistentVolumes)
# ---------------------------------------------------------------------------
cd "${ROOT}/10_ebs-csi-driver"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 11_storage-class
# Creates: default StorageClass "ebs-storage-class" (ebs.csi.aws.com)
# ---------------------------------------------------------------------------
cd "${ROOT}/11_storage-class"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 12_metrics-server
# Creates: metrics-server Helm release (kubectl top / HPA CPU metrics)
# ---------------------------------------------------------------------------
cd "${ROOT}/12_metrics-server"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 13_kube-prometheus-stack
# Creates: Prometheus, Grafana, Alertmanager Helm release in namespace monitoring
# ---------------------------------------------------------------------------
cd "${ROOT}/13_kube-prometheus-stack"
terraform init
terraform apply --auto-approve

echo "Done: 07_alb-controller → 13_kube-prometheus-stack."
