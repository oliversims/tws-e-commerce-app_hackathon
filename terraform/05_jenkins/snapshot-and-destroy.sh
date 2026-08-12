#!/usr/bin/env bash
# =============================================================================
# snapshot-and-destroy.sh
#
# Purpose: save Jenkins (jobs/plugins) as an AMI, then destroy the EC2 stack.
#
# Run in WSL from this folder:
#   cd terraform/05_jenkins
#   ./snapshot-and-destroy.sh
#
# Next time:
#   terraform apply
# =============================================================================

set -euo pipefail

# --- settings ---
REGION="us-east-1"                 # AWS region of the Jenkins server
INSTANCE_NAME="Jenkins-Automate"   # EC2 Name tag (must match terraform)
TFVARS_FILE="jenkins_ami_id.auto.tfvars"

# Always run from the folder where this script lives
cd "$(dirname "$0")"

# -----------------------------------------------------------------------------
# Step 1 — Find the running Jenkins EC2 instance ID
# -----------------------------------------------------------------------------
echo "Step 1: Find Jenkins EC2..."

INSTANCE_ID=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters \
    "Name=tag:Name,Values=$INSTANCE_NAME" \
    "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

echo "        Instance ID = $INSTANCE_ID"

# -----------------------------------------------------------------------------
# Step 2 — Create an AMI from that instance (snapshot of the disk)
# -----------------------------------------------------------------------------
echo "Step 2: Create AMI from Jenkins (may take a few minutes)..."

AMI_NAME="jenkins-$(date +%Y%m%d-%H%M%S)"

NEW_AMI_ID=$(aws ec2 create-image \
  --region "$REGION" \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --description "Jenkins saved before destroy" \
  --no-reboot \
  --query "ImageId" \
  --output text)

echo "        Waiting until AMI is available..."
aws ec2 wait image-available --region "$REGION" --image-ids "$NEW_AMI_ID"

echo "        AMI ID = $NEW_AMI_ID"

# -----------------------------------------------------------------------------
# Step 3 — Save the AMI ID so the next "terraform apply" uses it
#          Terraform auto-loads *.auto.tfvars in this folder.
# -----------------------------------------------------------------------------
echo "Step 3: Save AMI ID to $TFVARS_FILE..."

echo "jenkins_ami_id = \"$NEW_AMI_ID\"" > "$TFVARS_FILE"

echo "        Saved."

# -----------------------------------------------------------------------------
# Step 4 — Destroy the Jenkins Terraform stack (EC2, EIP, security group)
#          The AMI stays in your AWS account.
# -----------------------------------------------------------------------------
echo "Step 4: terraform destroy..."

terraform destroy -auto-approve

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo "Finished."
echo "Saved AMI: $NEW_AMI_ID"
echo "Next time run: terraform apply"
