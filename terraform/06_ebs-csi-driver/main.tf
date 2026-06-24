# 06_ebs-csi-driver — main.tf
# Creates an IRSA IAM role and deploys the AWS EBS CSI driver Helm chart.
# Required before persistent volumes (StorageClass) can work in the cluster.

# IAM role that lets the EBS CSI controller pod call AWS EBS APIs (IRSA).
module "iam_role" {
  source = "../modules/eks-oidc-iam-role"

  role_name         = "AmazonEKS_EBS_CSI_DriverRole"
  oidc_provider_url = data.terraform_remote_state.eks.outputs.oidc_provider_url
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
  ]

  tags = {
    Role = "role-ebs-csi-driver"
  }
}

# Helm release that installs the AWS EBS CSI driver in kube-system.
module "ebs_csi_driver" {
  source = "../modules/helm-release"

  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"

  app = {
    name          = "aws-ebs-csi-driver"
    description   = "aws-ebs-csi-driver"
    version       = "2.45.1"
    chart         = "aws-ebs-csi-driver"
    force_update  = true
    wait          = false
    recreate_pods = false
    deploy        = 1
  }

  values = [templatefile("${path.module}/values.yaml", {
    replicaCount = 1
  })]

  set = [
    {
      name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.iam_role.iam_role_arn
    }
  ]
}
