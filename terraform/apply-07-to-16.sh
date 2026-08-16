#!/usr/bin/env bash
# Apply bastion stacks 07_alb-controller → 16_logging.
# Prerequisites: 01–04 + 06 applied, SSH on bastion, kubeconfig ready.
# Run on the bastion (needs kubectl / Helm access to the private EKS API).
#
# Before 13: set Slack webhook api_url in 13_kube-prometheus-stack/values.yaml
# (bastion only — do not commit). Empty api_url prevents Alertmanager from starting.
# Before 15: apply 01_vpc + 04_eks so Karpenter discovery tags and IAM exist.
# Before 16: stacks 07, 08, 10, 11 (ALB, DNS, EBS CSI, StorageClass).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "==============================="
echo "STEP-1: Create ALB Controller using Terraform"
echo "==============================="
cd "${ROOT}/07_alb-controller"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-2: Create ExternalDNS using Terraform"
echo "==============================="
cd "${ROOT}/08_external-dns"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-3: Create Argo CD using Terraform"
echo "==============================="
cd "${ROOT}/09_argocd"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-4: Create EBS CSI Driver using Terraform"
echo "==============================="
cd "${ROOT}/10_ebs-csi-driver"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-5: Create StorageClass using Terraform"
echo "==============================="
cd "${ROOT}/11_storage-class"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-6: Create metrics-server using Terraform"
echo "==============================="
cd "${ROOT}/12_metrics-server"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-7: Create kube-prometheus-stack using Terraform"
echo "==============================="
cd "${ROOT}/13_kube-prometheus-stack"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-8: Create External Secrets using Terraform"
echo "==============================="
cd "${ROOT}/14_external-secrets"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-9: Create Karpenter using Terraform"
echo "==============================="
cd "${ROOT}/15_karpenter"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "==============================="
echo "STEP-10: Create logging (Elasticsearch, Filebeat, Kibana) using Terraform"
echo "==============================="
cd "${ROOT}/16_logging"
terraform init
terraform apply --auto-approve
sleep 15

echo
echo "Done: 07_alb-controller → 16_logging."
echo "Optional check: kubectl get pods -A; kubectl get nodepool,ec2nodeclass"
echo "Kibana: https://kibana.simsoliver.com"
