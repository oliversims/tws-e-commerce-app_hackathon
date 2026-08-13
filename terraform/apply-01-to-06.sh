#!/usr/bin/env bash
# Apply PC stacks 01_vpc → 06_bastion (skips 05_jenkins).
# Prerequisites: 00_state applied, backends updated, terra-key present.
# Run from a machine with AWS credentials (your PC / WSL).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 01_vpc
# Creates: VPC, 2 AZs, public + private subnets, IGW, single NAT gateway
# ---------------------------------------------------------------------------
cd "${ROOT}/01_vpc"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 02_route53_acm
# Creates: Route 53 hosted zone (simsoliver.com) + ACM wildcard cert (apex + *.)
# ---------------------------------------------------------------------------
cd "${ROOT}/02_route53_acm"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 03_keys
# Creates: EC2 key pair "terra-automate-key" from shared/terra-key.pub
# ---------------------------------------------------------------------------
cd "${ROOT}/03_keys"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 04_eks
# Creates: EKS control plane, managed node group, core addons (OIDC for IRSA)
# ---------------------------------------------------------------------------
cd "${ROOT}/04_eks"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 05_jenkins — skipped (not included in this script)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 06_bastion
# Creates: Bastion EC2, IAM role, EKS access entry, uploads 00_state to S3
# ---------------------------------------------------------------------------
cd "${ROOT}/06_bastion"
terraform init
terraform apply --auto-approve

echo "Done: 01_vpc → 04_eks → 06_bastion (05_jenkins skipped)."
