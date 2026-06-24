#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# 1. Install AWS CLI, kubectl, Terraform, and Helm
apt-get update -y
apt-get install -y curl unzip gnupg lsb-release git

# AWS CLI — talks to AWS (eks update-kubeconfig, etc.)
curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# kubectl — runs commands against the EKS cluster
curl -sL "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# Terraform — add HashiCorp apt repo, then install
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y terraform

# Helm — download, extract, put binary in PATH
curl -sL https://get.helm.sh/helm-v3.16.3-linux-amd64.tar.gz -o /tmp/helm.tar.gz
tar -xzf /tmp/helm.tar.gz -C /tmp
mv /tmp/linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# 2. Wait for IAM role credentials (from the EC2 instance profile)
until aws sts get-caller-identity --region ${region} >/dev/null 2>&1; do
  sleep 5
done

# 3. Create kubeconfig directory for ubuntu user
mkdir -p /home/ubuntu/.kube
chown ubuntu:ubuntu /home/ubuntu/.kube

# 4. Connect kubectl to EKS (retry until cluster is ready)
until sudo -u ubuntu aws eks update-kubeconfig \
    --name ${cluster_name} \
    --region ${region} \
    --kubeconfig /home/ubuntu/.kube/config \
  && sudo -u ubuntu kubectl --kubeconfig /home/ubuntu/.kube/config get nodes --request-timeout=30s; do
  sleep 10
done
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# 5. Set KUBECONFIG on every login
echo 'export KUBECONFIG=/home/ubuntu/.kube/config' > /etc/profile.d/kubeconfig.sh
chmod 644 /etc/profile.d/kubeconfig.sh

# 6. Copy terraform stacks 06-10 from GitHub (only these folders, not the full repo)
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/oliversims/tws-e-commerce-app_hackathon.git /home/ubuntu/repo
git -C /home/ubuntu/repo sparse-checkout set \
  terraform/modules \
  terraform/06_ebs-csi-driver \
  terraform/07_storage-class \
  terraform/08_alb-controller \
  terraform/09_argocd \
  terraform/10_kube-prometheus-stack
mv /home/ubuntu/repo/terraform /home/ubuntu/terraform
rm -rf /home/ubuntu/repo
chown -R ubuntu:ubuntu /home/ubuntu/terraform

touch /var/lib/bastion-kubectl-ready
