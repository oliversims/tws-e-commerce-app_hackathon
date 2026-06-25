# Upload 00_state to S3 so the bastion can download it on first boot (not in GitHub).

locals {
  state_key = "bastion/state.tfstate"
}

resource "aws_s3_object" "state" {
  bucket = local.backend_bucket
  key    = local.state_key
  source = "${path.module}/../00_state/terraform.tfstate"
  etag   = filemd5("${path.module}/../00_state/terraform.tfstate")
}
