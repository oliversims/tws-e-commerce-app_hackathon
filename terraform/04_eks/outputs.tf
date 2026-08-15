# 04_eks — outputs.tf
# Cluster identity for bastion-side Helm/IRSA stacks (07+).
# Apply from your PC; later stacks read these via terraform_remote_state.

output "eks_cluster_name" {
  description = "Used by 06_bastion, 07_alb-controller, 08_external-dns, and 15_karpenter"
  value       = module.eks.cluster_name
}

output "oidc_provider_url" {
  description = "Used by 07_alb-controller, 08_external-dns, 10_ebs-csi-driver, and 14_external-secrets"
  value       = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

output "karpenter_queue_name" {
  description = "Used by 15_karpenter Helm settings.interruptionQueue"
  value       = module.karpenter.queue_name
}

output "karpenter_node_iam_role_name" {
  description = "Used by 15_karpenter EC2NodeClass spec.role"
  value       = module.karpenter.node_iam_role_name
}
