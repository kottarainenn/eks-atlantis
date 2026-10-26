resource "helm_release" "atlantis" {
  name             = "atlantis"
  repository       = "https://runatlantis.github.io/helm-charts"
  chart            = "atlantis"
  version          = var.atlantis_chart_version
  namespace        = "atlantis"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      orgAllowlist = "github.com/${var.github_owner}/eks-atlantis"

      github = {
        user   = var.github_owner
        token  = var.github_token
        secret = var.github_webhook_secret
      }

      serviceAccount = {
        create = true
        name   = "atlantis"
      }

      volumeClaim = {
        enabled          = true
        storageClassName = "gp3"
        dataStorage      = "5Gi"
      }

      service = {
        type = "LoadBalancer"
      }

      repoConfig = file("${path.module}/repos.yaml")

      defaultTFVersion = "1.17.0"

      basicAuth = {
        username = var.basic_auth_username
        password = var.basic_auth_password
      }

      resources = {
        requests = { cpu = "100m", memory = "512Mi" }
        limits   = { memory = "1Gi" }
      }
    })
  ]

  depends_on = [
    kubernetes_storage_class_v1.gp3,
    aws_eks_pod_identity_association.atlantis
  ]
}