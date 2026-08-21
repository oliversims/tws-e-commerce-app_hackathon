# 05_jenkins — main.tf
# Jenkins CI EC2 in a public subnet with a stable Elastic IP.
# Apply from your PC after 01_vpc and 03_keys (included in apply-01-to-06.sh).

# Jenkins firewall only (SSH + 8080 from your IP). Jenkins does not talk to the
# private EKS API, so it does not get eks-api-client — that stays on the bastion.
resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "SSH and Jenkins UI from the operator IP only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "SSH from operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Jenkins UI from operator IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.os_image.id
  instance_type               = var.instance_type
  key_name                    = data.terraform_remote_state.keys.outputs.deployer_key_name
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/../shared/scripts/install_tools.sh")

  tags = {
    Name = "Jenkins-Automate"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

resource "aws_eip" "jenkins_server_ip" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name = "jenkins-eip"
  }
}
