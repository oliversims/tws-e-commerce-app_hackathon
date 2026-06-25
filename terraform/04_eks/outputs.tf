# 04_eks — outputs.tf

output "eks_cluster_name" {
  description = "Used by 07_alb-controller and 08_external-dns"
  value       = module.eks.cluster_name
}

output "oidc_provider_url" {
  description = "Used by 11_ebs-csi-driver, 07_alb-controller, and 08_external-dns"
  value       = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}
