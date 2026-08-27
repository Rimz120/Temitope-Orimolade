output "cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.lab.endpoint
}

output "cluster_resource_id" {
  description = "Resource ID, used in the IAM policy dbuser ARN"
  value       = aws_rds_cluster.lab.cluster_resource_id
}

output "access_group_role_arn" {
  description = "ARN of the IAM role standing in for the AD GroupID"
  value       = aws_iam_role.access_group.arn
}

output "generate_iam_token_command" {
  description = "Command to generate a short lived IAM auth token once you've assumed access_group_role_arn"
  value       = "aws rds generate-db-auth-token --hostname ${aws_rds_cluster.lab.endpoint} --port 5432 --username printer_admins_iam --region ${var.aws_region}"
}
