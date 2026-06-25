# 06_bastion — main.tf
# Bastion jump host with IAM role for EKS — kubectl ready after SSH (no aws configure).
# Apply after 04_eks.

# Firewall: allows SSH, HTTP, and HTTPS from anywhere into the Bastion host.
resource "aws_security_group" "allow_user_bastion" {
  name        = "bastion_host_SG"
  description = "Allow user to connect"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  dynamic "ingress" {
    for_each = [
      { description = "port 22 allow", from = 22, to = 22, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { description = "port 80 allow", from = 80, to = 80, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { description = "port 443 allow", from = 443, to = 443, protocol = "tcp", cidr = ["0.0.0.0/0"] }
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
    description = " allow all outgoing traffic "
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion_security"
  }
}

# IAM role — instance profile supplies AWS credentials (replaces manual aws configure).
resource "aws_iam_role" "bastion" {
  name = "${data.terraform_remote_state.vpc.outputs.cluster_name}-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "bastion_eks_describe" {
  name = "eks-describe-cluster"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = "*"
    }]
  })
}

# S3 + IAM for running terraform stacks 06-10 on the bastion.
resource "aws_iam_role_policy" "bastion_terraform_stacks" {
  name = "terraform-stacks-06-10"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${local.backend_bucket}",
          "arn:aws:s3:::${local.backend_bucket}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRoleTags",
          "iam:ListInstanceProfilesForRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:GetOpenIDConnectProvider",
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonEKS_EBS_CSI_DriverRole",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonEKSLoadBalancerControllerRole",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AWSLoadBalancerControllerIAMPolicy",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/*",
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${data.terraform_remote_state.vpc.outputs.cluster_name}-bastion"
  role = aws_iam_role.bastion.name
}

# Grant the bastion role cluster-admin on the private EKS API.
resource "aws_eks_access_entry" "bastion" {
  cluster_name  = data.terraform_remote_state.eks.outputs.eks_cluster_name
  principal_arn = aws_iam_role.bastion.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "bastion" {
  cluster_name  = data.terraform_remote_state.eks.outputs.eks_cluster_name
  principal_arn = aws_iam_role.bastion.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# Ubuntu EC2 instance in a public subnet — jump box for kubectl and private API access.
resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.os_image.id
  instance_type               = var.instance_type
  key_name                    = data.terraform_remote_state.keys.outputs.deployer_key_name
  vpc_security_group_ids      = [aws_security_group.allow_user_bastion.id]
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/../shared/scripts/bastion_user_data.sh", {
    cluster_name        = data.terraform_remote_state.eks.outputs.eks_cluster_name
    region              = local.region
    state_bucket        = local.backend_bucket
    state_key = local.state_key
  })

  tags = {
    Name = "Bastion-Host"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  depends_on = [
    aws_eks_access_policy_association.bastion,
    aws_s3_object.state,
  ]
}
