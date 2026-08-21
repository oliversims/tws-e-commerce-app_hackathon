# 04_eks — main.tf
# EKS cluster, three-AZ managed node group, core addons, Karpenter IAM/SQS.
# Apply from your PC after 01_vpc. Private API — kubectl via bastion.

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

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

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

  # That block does not create eks-api-client. It says: on the cluster SG that
  # EKS already owns, allow 443 from whoever has eks-api-client.
  cluster_security_group_additional_rules = {
    api_from_bastion = {
      description              = "HTTPS from bastion (eks-api-client SG)"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = data.terraform_remote_state.vpc.outputs.eks_api_client_sg_id
    }
  }

  cluster_addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
  }

  eks_managed_node_groups = {
    tws-demo-ng = {
      # One managed worker per private subnet (us-east-1a/b/c). Extra capacity
      # comes from 15_karpenter. Terraform ignores desired_size after create.
      min_size     = 3
      max_size     = 5
      desired_size = 3

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      disk_size      = 35

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  # Module recommended rules already allow control-plane → kubelet/webhooks.
  # Self-all is required so VPC CNI pods (sharing this SG) can talk across nodes.
  # ALB → pod rules are added by the AWS Load Balancer Controller (target-type: ip).
  node_security_group_enable_recommended_rules = true
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node (pod-to-pod via VPC CNI)"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
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
