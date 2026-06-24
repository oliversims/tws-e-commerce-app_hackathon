# 03_eks — outputs.tf

output "eks_cluster_name" {
  description = "Used by 08_alb-controller"
  value       = module.eks.cluster_name
}

output "oidc_provider_url" {
  description = "Used by 06_ebs-csi-driver and 08_alb-controller"
  value       = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}
