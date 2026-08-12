#!/usr/bin/env bash
# Destroy bastion stacks 13_kube-prometheus-stack → 07_alb-controller.
# Run on the bastion (needs kubectl / Helm access to the private EKS API).
# Order is the reverse of apply-07-to-13.sh.
#
# Before running: delete the easyshop Argo CD app / namespace if present
# (Ingresses/ALBs left behind can block later destroys).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 13_kube-prometheus-stack
# Destroys: Prometheus, Grafana, Alertmanager Helm release (namespace monitoring)
# ---------------------------------------------------------------------------
cd "${ROOT}/13_kube-prometheus-stack"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 12_metrics-server
# Destroys: metrics-server Helm release in kube-system
# ---------------------------------------------------------------------------
cd "${ROOT}/12_metrics-server"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 11_storage-class
# Destroys: default StorageClass "ebs-storage-class"
# ---------------------------------------------------------------------------
cd "${ROOT}/11_storage-class"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 10_ebs-csi-driver
# Destroys: EBS CSI driver Helm release + IRSA role
# ---------------------------------------------------------------------------
cd "${ROOT}/10_ebs-csi-driver"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 09_argocd
# Destroys: Argo CD Helm release (namespace argocd)
# ---------------------------------------------------------------------------
cd "${ROOT}/09_argocd"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 08_external-dns
# Destroys: ExternalDNS Helm release + IRSA policy/role
# ---------------------------------------------------------------------------
cd "${ROOT}/08_external-dns"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 07_alb-controller
# Destroys: AWS Load Balancer Controller Helm release + IRSA policy/role
# ---------------------------------------------------------------------------
cd "${ROOT}/07_alb-controller"
terraform init
terraform destroy --auto-approve

echo "Done: destroyed 13_kube-prometheus-stack → 07_alb-controller."
