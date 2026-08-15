# Reusable Helm chart installer. Used by bastion stacks 07–15.

resource "helm_release" "this" {
  namespace        = var.namespace
  repository       = var.repository
  name             = var.app.name
  version          = var.app.version
  chart            = var.app.chart
  force_update     = lookup(var.app, "force_update", false)
  wait             = lookup(var.app, "wait", true)
  recreate_pods    = lookup(var.app, "recreate_pods", false)
  create_namespace = lookup(var.app, "create_namespace", false)
  values           = var.values
  set              = var.set
}
