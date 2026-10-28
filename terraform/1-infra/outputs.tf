output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "region" {
  value = "eu-north-1"
}

output "eks_admin_role_arn" {
  value = aws_iam_role.eks_admin.arn
}

output "eks_read_only_role_arn" {
  value = aws_iam_role.eks_read_only.arn
}

output "state_bucket_name" {
  value = var.state_bucket_name
}