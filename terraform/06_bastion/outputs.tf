# 06_bastion — outputs.tf
# SSH helper so you can jump onto the bastion from your PC.
# After first boot (~1 min), kubectl is already configured for the private EKS API.

# Used by you (PC) — start of the bastion workflow for stacks 07–13.
output "ssh_command" {
  description = "SSH into the bastion (kubectl is auto-configured after ~1 min first boot)"
  value       = "ssh -i ../shared/terra-key ubuntu@${aws_instance.bastion_host.public_ip}"
}
