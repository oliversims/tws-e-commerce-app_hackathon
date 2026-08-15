# 04_eks — main.tf
# EKS cluster, managed node group (bootstrap for Karpenter), and core addons.
# Apply from your PC after 01_vpc and 03_keys. Private API — use bastion/Jenkins.

resource "aws_security_group" "node_group_remote_access" {
  name   = "${local.name}-node-ssh"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "SSH from VPC (bastion / Jenkins)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr]
  }

  egress {
    description = "allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                    = local.name
  cluster_version                 = "1.31"
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true
  # Skip module time_sleep before node groups. Default 30s is enough in AWS;
  # terraform-provider-time 0.14.x can hang that wait on WSL.
  dataplane_wait_duration = "0s"

  access_entries = {
    terraform = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  cluster_security_group_additional_rules = {
    vpc_https = {
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr]
      description = "HTTPS from VPC (bastion / Jenkins)"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      type        = "ingress"
    }
  }

  cluster_addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
  }

  vpc_id                   = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.vpc.outputs.private_subnets
  control_plane_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  eks_managed_node_group_defaults = {
    instance_types                        = ["t3.large"]
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    tws-demo-ng = {
      # Bootstrap node for Karpenter + system pods. Extra workers come from 15_karpenter
      # (Terraform ignores desired_size after create).
      min_size     = 1
      max_size     = 5
      desired_size = 1

      instance_types             = ["t3.large"]
      capacity_type              = "SPOT"
      disk_size                  = 35
      use_custom_launch_template = false

      remote_access = {
        ec2_ssh_key               = data.terraform_remote_state.keys.outputs.deployer_key_name
        source_security_group_ids = [aws_security_group.node_group_remote_access.id]
      }

      tags = {
        Name        = "tws-demo-ng"
        Environment = "dev"
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = local.name
  }

  tags = local.tags
}

# IAM + SQS interruption queue for Karpenter (Helm/NodePool live in 15_karpenter).
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = module.eks.cluster_name
  namespace    = "karpenter"

  enable_v1_permissions           = true
  enable_pod_identity             = true
  create_pod_identity_association = true
  enable_irsa                     = false

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}
