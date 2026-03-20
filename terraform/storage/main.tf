resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
  }

  provisioner = "ebs.csi.aws.com"

  parameters = {
    type = "gp3"
  }

  reclaim_policy = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}
