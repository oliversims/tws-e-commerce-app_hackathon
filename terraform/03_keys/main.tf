# 03_keys — main.tf
# Registers your SSH public key in AWS so EC2 (and EKS node SSH) can use it.
# Apply from your PC after 00_state. Requires shared/terra-key.pub on disk.
# Output key name is consumed by 04_eks, 05_jenkins, and 06_bastion.

# Registers the public key from shared/terra-key.pub as an AWS key pair.
# The private key stays on your machine — never commit it.
resource "aws_key_pair" "deployer" {
  key_name   = "terra-automate-key"
  public_key = file("${path.module}/../shared/terra-key.pub")
}
