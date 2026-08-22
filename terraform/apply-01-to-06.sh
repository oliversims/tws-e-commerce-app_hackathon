#!/usr/bin/env bash
# Apply PC stacks 01_vpc → 06_bastion, including 05_jenkins.
# Prerequisites: 00_state applied, backends updated, terra-key present.
# Run from a machine with AWS credentials (your PC / WSL).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "==============================="
echo "STEP-1: Create VPC using Terraform"
echo "==============================="
cd "${ROOT}/01_vpc"
terraform init --reconfigure
terraform apply --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-2: Create Route53/ACM using Terraform"
echo "==============================="
cd "${ROOT}/02_route53_acm"
terraform init --reconfigure
terraform apply --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-3: Create keys using Terraform"
echo "==============================="
cd "${ROOT}/03_keys"
terraform init --reconfigure
terraform apply --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-4: Create EKS using Terraform"
echo "==============================="
cd "${ROOT}/04_eks"
terraform init --reconfigure
terraform apply --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-5: Create Jenkins using Terraform"
echo "==============================="
cd "${ROOT}/05_jenkins"
terraform init --reconfigure
terraform apply --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-6: Create bastion using Terraform"
echo "==============================="
cd "${ROOT}/06_bastion"
terraform init --reconfigure
terraform apply --auto-approve
sleep 10

echo
echo "Done: 01_vpc → 02_route53_acm → 03_keys → 04_eks → 06_bastion."
echo "Jenkins URL / SSH: cd ${ROOT}/05_jenkins && terraform output"
echo "Bastion SSH:       cd ${ROOT}/06_bastion && terraform output -raw ssh_command"
