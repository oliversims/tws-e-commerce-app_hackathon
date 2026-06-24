# 05_bastion — outputs.tf

output "ssh_command" {
  description = "SSH into the bastion from your machine (run from terraform/05_bastion)"
  value       = "ssh -i ../shared/terra-key ubuntu@${aws_instance.bastion_host.public_ip}"
}

output "setup_kubeconfig_command" {
  description = "Run on the bastion after 03_eks is applied (configure aws credentials on bastion first)"
  value       = "aws eks update-kubeconfig --name ${data.terraform_remote_state.vpc.outputs.cluster_name} --region ${local.region}"
}

output "kubectl_get_nodes_command" {
  description = "Run on the bastion after setup_kubeconfig_command to verify cluster access"
  value       = "kubectl get nodes"
}
