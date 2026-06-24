# 03_eks — main.tf
# Creates the EKS cluster, worker nodes, and required addons.

# Firewall rules allowing SSH (port 22) into EKS worker nodes for debugging.
resource "aws_security_group" "node_group_remote_access" {
  name   = "allow HTTP"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "port 22 allow"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = " allow all outgoing traffic "
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EKS control plane, worker node group, and core addons (CoreDNS, kube-proxy, VPC-CNI).
# API endpoint is private-only — access via Bastion or Jenkins inside the VPC.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                    = local.name
  cluster_version                 = "1.31"
  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  # Grants cluster-admin to whoever runs terraform apply (AWS credentials in use).
  access_entries = {
    example = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Allows HTTPS from Jenkins/Bastion to reach the private Kubernetes API.
  cluster_security_group_additional_rules = {
    access_for_bastion_jenkins_hosts = {
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all HTTPS traffic from jenkins and Bastion host"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      type        = "ingress"
    }
  }

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  vpc_id                   = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.vpc.outputs.private_subnets
  control_plane_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  eks_managed_node_group_defaults = {
    instance_types = ["t3.large"]
    attach_cluster_primary_security_group = true
  }

  # SPOT worker nodes — 1 node by default, scales up to 3.
  eks_managed_node_groups = {
    tws-demo-ng = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      disk_size                  = 35
      use_custom_launch_template = false

      remote_access = {
        ec2_ssh_key               = data.terraform_remote_state.keys.outputs.deployer_key_name
        source_security_group_ids = [aws_security_group.node_group_remote_access.id]
      }

      tags = {
        Name        = "tws-demo-ng"
        Environment = "dev"
        ExtraTag    = "e-commerce-app"
      }
    }
  }

  tags = local.tags
}

# Looks up running EC2 instances tagged as EKS nodes (used for output IPs).
data "aws_instances" "eks_nodes" {
  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}
