resource "github_repository_webhook" "atlantis" {
  repository = var.github_repo
  active     = true
  events     = ["issue_comment", "pull_request", "pull_request_review", "push"]

  configuration {
    url          = "http://${local.atlantis_host}/events"
    content_type = "json"
    secret       = var.github_webhook_secret
  }
}