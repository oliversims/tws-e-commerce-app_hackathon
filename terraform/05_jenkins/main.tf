# 05_jenkins — main.tf
# Jenkins CI EC2 in a public subnet with a stable Elastic IP.
# Apply from your PC after 01_vpc and 03_keys (included in apply-01-to-06.sh).

resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "SSH, HTTP, HTTPS, and Jenkins UI"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  dynamic "ingress" {
    for_each = [
      { description = "SSH", from = 22, to = 22, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { description = "HTTP", from = 80, to = 80, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { description = "HTTPS", from = 443, to = 443, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { description = "Jenkins UI", from = 8080, to = 8080, protocol = "tcp", cidr = ["0.0.0.0/0"] }
    ]
    content {
      description = ingress.value.description
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr
    }
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
  ami                    = data.aws_ami.os_image.id
  instance_type          = var.instance_type
  key_name               = data.terraform_remote_state.keys.outputs.deployer_key_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  user_data              = file("${path.module}/../shared/scripts/install_tools.sh")

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
}
