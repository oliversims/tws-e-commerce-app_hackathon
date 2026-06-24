#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# Core packages (Java 21 for Jenkins on Ubuntu 24.04)
apt-get update
apt-get install -y curl fontconfig openjdk-21-jre

# Jenkins — 2026 repo signing key (2023 key fails with NO_PUBKEY 7198F4B714ABFC68)
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# Docker
apt-get install -y docker.io
usermod -aG docker ubuntu
usermod -aG docker jenkins

systemctl enable docker
systemctl restart docker
systemctl restart jenkins

# Trivy (apt-key removed on Ubuntu 24.04)
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(. /etc/os-release && echo "${VERSION_CODENAME}") main" \
  | tee /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install -y trivy

# AWS CLI + Helm
apt-get install -y snapd
snap install aws-cli --classic
snap install helm --classic
