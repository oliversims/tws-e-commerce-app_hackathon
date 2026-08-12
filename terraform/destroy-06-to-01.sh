#!/usr/bin/env bash
# Destroy PC stacks 06_bastion → 01_vpc (skips 05_jenkins).
# Prerequisites: bastion stacks 07–13 already destroyed (run destroy-13-to-07.sh first).
# Run from a machine with AWS credentials (your PC / WSL).
# Order is the reverse of apply-01-to-06.sh.
#
# After 06 is destroyed you can no longer SSH to the bastion.
# Does not destroy 00_state (S3 bucket) — remove that separately if needed.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 06_bastion
# Destroys: Bastion EC2, IAM role, EKS access entry, related SG / uploads
# ---------------------------------------------------------------------------
cd "${ROOT}/06_bastion"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 05_jenkins — skipped (not managed by apply-01-to-06.sh)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 04_eks
# Destroys: EKS control plane, managed node group, core addons
# ---------------------------------------------------------------------------
cd "${ROOT}/04_eks"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 03_keys
# Destroys: EC2 key pair "terra-automate-key"
# ---------------------------------------------------------------------------
cd "${ROOT}/03_keys"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 02_route53_acm
# Destroys: ACM wildcard cert + Route 53 hosted zone (simsoliver.com)
# ---------------------------------------------------------------------------
cd "${ROOT}/02_route53_acm"
terraform init
terraform destroy --auto-approve

# ---------------------------------------------------------------------------
# 01_vpc
# Destroys: VPC, subnets, IGW, NAT gateway, related networking
# ---------------------------------------------------------------------------
cd "${ROOT}/01_vpc"
terraform init
terraform destroy --auto-approve

echo "Done: destroyed 06_bastion → 01_vpc (05_jenkins skipped; 00_state kept)."
