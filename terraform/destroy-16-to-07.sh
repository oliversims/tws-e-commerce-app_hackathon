#!/usr/bin/env bash
# Destroy bastion stacks 16_logging → 07_alb-controller.
# Run on the bastion (needs kubectl / Helm access to the private EKS API).
# Order is the reverse of apply-07-to-16.sh.
#
# Before running: delete EasyShop (see TEARDOWN.txt section 1).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "==============================="
echo "STEP-1: Destroy logging using Terraform"
echo "==============================="
cd "${ROOT}/16_logging"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-2: Destroy Karpenter using Terraform"
echo "==============================="
cd "${ROOT}/15_karpenter"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-3: Destroy External Secrets using Terraform"
echo "==============================="
cd "${ROOT}/14_external-secrets"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-4: Destroy kube-prometheus-stack using Terraform"
echo "==============================="
cd "${ROOT}/13_kube-prometheus-stack"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-5: Destroy metrics-server using Terraform"
echo "==============================="
cd "${ROOT}/12_metrics-server"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-6: Destroy StorageClass using Terraform"
echo "==============================="
cd "${ROOT}/11_storage-class"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-7: Destroy EBS CSI Driver using Terraform"
echo "==============================="
cd "${ROOT}/10_ebs-csi-driver"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-8: Destroy Argo CD using Terraform"
echo "==============================="
cd "${ROOT}/09_argocd"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-9: Destroy ExternalDNS using Terraform"
echo "==============================="
cd "${ROOT}/08_external-dns"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-10: Destroy ALB Controller using Terraform"
echo "==============================="
cd "${ROOT}/07_alb-controller"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "Done: destroyed 16_logging → 07_alb-controller."
