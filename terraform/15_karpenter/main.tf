# 15_karpenter — main.tf
# Karpenter controller (Helm) + NodePool/EC2NodeClass.
# Run on the bastion after 04_eks (IAM/SQS + discovery tags) and 12_metrics-server (HPA).
# Scales workers when pods are Pending (HPA → more pods → Karpenter → more nodes).

module "karpenter_crd" {
  source = "../modules/helm-release"

  namespace  = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"

  app = {
    name             = "karpenter-crd"
    version          = local.karpenter_version
    chart            = "karpenter-crd"
    force_update     = true
    wait             = true
    recreate_pods    = false
    create_namespace = true
  }
}

module "karpenter" {
  source = "../modules/helm-release"

  namespace  = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"

  app = {
    name          = "karpenter"
    version       = local.karpenter_version
    chart         = "karpenter"
    force_update  = true
    wait          = true
    recreate_pods = false
  }

  values = [templatefile("${path.module}/values.yaml", {
    clusterName       = data.terraform_remote_state.eks.outputs.eks_cluster_name
    interruptionQueue = data.terraform_remote_state.eks.outputs.karpenter_queue_name
  })]

  depends_on = [module.karpenter_crd]
}

resource "kubectl_manifest" "ec2nodeclass" {
  yaml_body = templatefile("${path.module}/ec2nodeclass.yaml", {
    cluster_name        = data.terraform_remote_state.eks.outputs.eks_cluster_name
    node_iam_role_name  = data.terraform_remote_state.eks.outputs.karpenter_node_iam_role_name
  })

  server_side_apply = true
  wait              = false

  depends_on = [module.karpenter]
}

resource "kubectl_manifest" "nodepool" {
  yaml_body = file("${path.module}/nodepool.yaml")

  server_side_apply = true
  wait              = false

  depends_on = [kubectl_manifest.ec2nodeclass]
}
