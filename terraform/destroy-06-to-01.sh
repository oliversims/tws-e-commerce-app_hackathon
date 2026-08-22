#!/usr/bin/env bash
# Destroy PC stacks 06_bastion → 01_vpc, including 05_jenkins, then 00_state.
# Prerequisites: bastion stacks 07–16 already destroyed (run destroy-16-to-07.sh first).
# Run from a machine with AWS credentials (your PC / WSL).
# Order is the reverse of apply-01-to-06.sh.
#
# After 06 is destroyed you can no longer SSH to the bastion.
# 00_state (the S3 tfstate bucket) is last: stacks 01–06 store their state there.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "==============================="
echo "STEP-1: Destroy bastion using Terraform"
echo "==============================="
cd "${ROOT}/06_bastion"
terraform init
terraform destroy --auto-approve
sleep 10

# echo
# echo "==============================="
# echo "STEP-2: Destroy Jenkins using Terraform"
# echo "==============================="
# cd "${ROOT}/05_jenkins"
# terraform init
# terraform destroy --auto-approve
# sleep 10

echo
echo "==============================="
echo "STEP-3: Destroy EKS using Terraform"
echo "==============================="
cd "${ROOT}/04_eks"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-4: Destroy keys using Terraform"
echo "==============================="
cd "${ROOT}/03_keys"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-5: Destroy Route53/ACM using Terraform"
echo "==============================="
cd "${ROOT}/02_route53_acm"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-6: Destroy VPC using Terraform"
echo "==============================="
cd "${ROOT}/01_vpc"
terraform init
terraform destroy --auto-approve
sleep 10

echo
echo "==============================="
echo "STEP-7: Destroy state bucket using Terraform"
echo "==============================="
cd "${ROOT}/00_state"
terraform init
terraform destroy --auto-approve

echo
echo "Done: destroyed 06_bastion → 05_jenkins → 04_eks → 03_keys → 02_route53_acm → 01_vpc → 00_state."
