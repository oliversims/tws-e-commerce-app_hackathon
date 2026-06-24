# 08_alb-controller — main.tf
# Creates IAM policy/role and deploys the AWS Load Balancer Controller Helm chart.
# Enables Kubernetes Ingress resources to provision ALBs in AWS.

# Custom IAM policy granting permissions to create and manage ALBs/NLBs.
resource "aws_iam_policy" "alb_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  path   = "/"
  policy = file("${path.module}/iam_policy.json")
}

# IAM role that lets the ALB controller pod manage AWS load balancers (IRSA).
module "iam_role" {
  source = "../modules/eks-oidc-iam-role"

  role_name         = "AmazonEKSLoadBalancerControllerRole"
  oidc_provider_url = data.terraform_remote_state.eks.outputs.oidc_provider_url
  policy_arns       = [aws_iam_policy.alb_policy.arn]

  tags = {
    Role = "role-alb-controller"
  }
}

# Helm release that installs the AWS Load Balancer Controller in kube-system.
module "alb_controller" {
  source = "../modules/helm-release"

  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"

  app = {
    name          = "aws-load-balancer-controller"
    description   = "aws-load-balancer-controller"
    version       = "1.13.3"
    chart         = "aws-load-balancer-controller"
    force_update  = true
    wait          = false
    recreate_pods = false
    deploy        = 1
  }

  values = [templatefile("${path.module}/values.yaml", {
    replicaCount = 1
    clusterName  = data.terraform_remote_state.eks.outputs.eks_cluster_name
    region       = data.terraform_remote_state.vpc.outputs.region
    vpcId        = data.terraform_remote_state.vpc.outputs.vpc_id
  })]

  set = [
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.iam_role.iam_role_arn
    }
  ]
}
