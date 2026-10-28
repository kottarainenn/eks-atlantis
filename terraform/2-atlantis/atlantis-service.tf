data "kubernetes_service_v1" "atlantis" {
  metadata {
    name      = "atlantis"
    namespace = "atlantis"
  }
  depends_on = [helm_release.atlantis]
}

locals {
  atlantis_host = data.kubernetes_service_v1.atlantis.status[0].load_balancer[0].ingress[0].hostname
}