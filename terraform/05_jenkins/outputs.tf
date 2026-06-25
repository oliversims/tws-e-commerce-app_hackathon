# 05_jenkins — outputs.tf

locals {
  jenkins_host = aws_eip.jenkins_server_ip.public_ip
}

output "ssh_command" {
  description = "SSH into the Jenkins server"
  value       = "ssh -i ../shared/terra-key ubuntu@${local.jenkins_host}"
}

output "jenkins_url" {
  description = "Open in your browser (wait a few minutes after apply for Jenkins to finish installing)"
  value       = "http://${local.jenkins_host}:8080"
}

output "jenkins_get_password_command" {
  description = "Run on the Jenkins server after SSH — prints the initial admin password"
  value       = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}
