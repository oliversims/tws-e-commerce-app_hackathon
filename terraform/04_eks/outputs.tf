# 04_eks — outputs.tf
# Cluster identity for bastion-side Helm/IRSA stacks (07+).
# Apply from your PC; later stacks read these via terraform_remote_state.

output "eks_cluster_name" {
  description = "Used by 06_bastion, 07_alb-controller, and 08_external-dns"
  value       = module.eks.cluster_name
}

output "oidc_provider_url" {
  description = "Used by 07_alb-controller, 08_external-dns, and 10_ebs-csi-driver"
  value       = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}
