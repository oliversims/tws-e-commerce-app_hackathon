# 16_logging — main.tf
# Elasticsearch, Filebeat, and Kibana via Helm. Apply on the bastion after
# 07_alb-controller, 08_external-dns, and 10+11 storage.

module "elasticsearch" {
  source = "../modules/helm-release"

  namespace  = "logging"
  repository = "https://helm.elastic.co"

  app = {
    name             = "my-elasticsearch"
    version          = "8.5.1"
    chart            = "elasticsearch"
    force_update     = true
    wait             = true
    recreate_pods    = false
    create_namespace = true
  }

  values = [file("${path.module}/../../helm-values/elasticsearch.yaml")]
}

module "filebeat" {
  source = "../modules/helm-release"

  namespace  = "logging"
  repository = "https://helm.elastic.co"

  app = {
    name          = "my-filebeat"
    version       = "8.5.1"
    chart         = "filebeat"
    force_update  = true
    wait          = false
    recreate_pods = false
  }

  values = [file("${path.module}/../../helm-values/filebeat.yaml")]

  depends_on = [module.elasticsearch]
}

module "kibana" {
  source = "../modules/helm-release"

  namespace  = "logging"
  repository = "https://helm.elastic.co"

  app = {
    name          = "my-kibana"
    version       = "8.5.1"
    chart         = "kibana"
    force_update  = true
    wait          = false
    recreate_pods = false
  }

  values = [file("${path.module}/../../helm-values/kibana.yaml")]

  depends_on = [module.elasticsearch]
}
