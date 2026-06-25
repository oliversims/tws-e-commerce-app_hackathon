# 03_keys — main.tf
# Uploads your SSH public key to AWS so EC2 and EKS can use it.

# Registers the public key from shared/terra-key.pub as an AWS key pair.
# The private key stays on your machine — never commit it.
resource "aws_key_pair" "deployer" {
  key_name   = "terra-automate-key"
  public_key = file("${path.module}/../shared/terra-key.pub")
}
