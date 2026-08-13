#!/usr/bin/env bash
# Apply PC stacks 01_vpc → 06_bastion (skips 05_jenkins).
# Prerequisites: 00_state applied, backends updated, terra-key present.
# Run from a machine with AWS credentials (your PC / WSL).
#
# Terraform already waits for AWS resource create within each stack.
# Extra waits below cover post-apply readiness (cert ISSUED, EKS nodes, bastion up)
# before starting the next stack.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGION="${AWS_REGION:-us-east-1}"

# ---------------------------------------------------------------------------
# 01_vpc
# Creates: VPC, 2 AZs, public + private subnets, IGW, single NAT gateway
# Typical cold create: several minutes (NAT gateway is usually the slow part)
# ---------------------------------------------------------------------------
cd "${ROOT}/01_vpc"
terraform init
terraform apply --auto-approve

# ---------------------------------------------------------------------------
# 02_route53_acm
# Creates: Route 53 hosted zone (simsoliver.com) + ACM wildcard cert (apex + *.)
# Wait until ACM certificate is ISSUED before continuing (DNS validation).
# ---------------------------------------------------------------------------
cd "${ROOT}/02_route53_acm"
terraform init
terraform apply --auto-approve
CERT_ARN="$(terraform output -raw certificate_arn)"
echo ">> waiting for ACM certificate ISSUED: ${CERT_ARN}"
aws acm wait certificate-validated --certificate-arn "${CERT_ARN}" --region "${REGION}"
echo ">> ACM certificate is ISSUED"

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
# Typical cold create: 10–20+ minutes. Wait until cluster + nodegroup are ACTIVE.
# ---------------------------------------------------------------------------
cd "${ROOT}/04_eks"
terraform init
terraform apply --auto-approve
CLUSTER="$(terraform output -raw eks_cluster_name)"
echo ">> waiting for EKS cluster ACTIVE: ${CLUSTER}"
aws eks wait cluster-active --name "${CLUSTER}" --region "${REGION}"
NG="$(aws eks list-nodegroups --cluster-name "${CLUSTER}" --region "${REGION}" --query 'nodegroups[0]' --output text)"
if [ -n "${NG}" ] && [ "${NG}" != "None" ]; then
  echo ">> waiting for nodegroup ACTIVE: ${NG}"
  aws eks wait nodegroup-active --cluster-name "${CLUSTER}" --nodegroup-name "${NG}" --region "${REGION}"
fi
echo ">> EKS cluster and nodegroup are ACTIVE"

# ---------------------------------------------------------------------------
# 05_jenkins — skipped (not included in this script)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 06_bastion
# Creates: Bastion EC2, IAM role, EKS access entry, uploads 00_state to S3
# Wait until instance is running and status checks pass (user_data still boots).
# ---------------------------------------------------------------------------
cd "${ROOT}/06_bastion"
terraform init
terraform apply --auto-approve
IID="$(terraform state show aws_instance.bastion_host 2>/dev/null | awk '/^id /{print $3; exit}' | tr -d '"')"
if [ -z "${IID}" ]; then
  IID="$(aws ec2 describe-instances --region "${REGION}" --filters "Name=tag:Name,Values=Bastion-Host" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)"
fi
echo ">> waiting for bastion instance ${IID} running + status-ok"
aws ec2 wait instance-running --instance-ids "${IID}" --region "${REGION}"
aws ec2 wait instance-status-ok --instance-ids "${IID}" --region "${REGION}" || true
echo ">> bastion EC2 is up (user_data may still be installing tools for a few minutes)"

echo "Done: 01_vpc → 04_eks → 06_bastion (05_jenkins skipped)."
