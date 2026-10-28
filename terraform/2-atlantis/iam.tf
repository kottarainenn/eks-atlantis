resource "aws_iam_role" "atlantis" {
  name = "atlantis-pod-identity"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy" "atlantis" {
  name = "atlantis-demo-permissions"
  role = aws_iam_role.atlantis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StateBucketList"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${data.terraform_remote_state.infra.outputs.state_bucket_name}"
      },
      {
        Sid      = "StateBucketDemoObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${data.terraform_remote_state.infra.outputs.state_bucket_name}/demo/*"
      },
      {
        Sid      = "DemoResources"
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = ["arn:aws:s3:::atlantis-demo-*", "arn:aws:s3:::atlantis-demo-*/*"]
      }
    ]
  })
}

resource "aws_eks_pod_identity_association" "atlantis" {
  cluster_name    = local.cluster_name
  namespace       = "atlantis"
  service_account = "atlantis"
  role_arn        = aws_iam_role.atlantis.arn
}