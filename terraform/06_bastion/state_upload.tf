# 06_bastion — state_upload.tf
# Uploads 00_state/terraform.tfstate to S3 so the bastion can download it on first boot.
# Needed because that local state file is gitignored and not available from GitHub.
# Apply from your PC as part of 06_bastion (runs with main.tf).

resource "aws_s3_object" "state" {
  bucket = local.backend_bucket
  key    = local.state_key
  source = "${path.module}/../00_state/terraform.tfstate"
  etag   = filemd5("${path.module}/../00_state/terraform.tfstate")
}
