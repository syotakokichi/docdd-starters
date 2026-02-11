output "log_group_arns" {
  value = { for k, v in aws_cloudwatch_log_group.app : k => v.arn }
}
