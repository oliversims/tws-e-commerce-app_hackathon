# 12_storage-class — main.tf
# Creates the default Kubernetes StorageClass backed by the EBS CSI driver.

# Default StorageClass — new PVCs automatically use EBS volumes via the CSI driver.
resource "kubernetes_storage_class_v1" "ebs" {
  metadata {
    name = "ebs-storage-class"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  depends_on = [data.terraform_remote_state.ebs_csi_driver]
}
