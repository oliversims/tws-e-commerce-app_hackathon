# 06_bastion — outputs.tf

output "ssh_command" {
  description = "SSH into the bastion (kubectl is auto-configured after ~1 min first boot)"
  value       = "ssh -i ../shared/terra-key ubuntu@${aws_instance.bastion_host.public_ip}"
}
