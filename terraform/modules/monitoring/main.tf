# Monitoring Module - CloudWatch

resource "aws_cloudwatch_log_group" "app" {
  for_each = toset(var.log_group_names)

  name              = "/ecs/${var.project_name}-${var.environment}/${each.value}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.value}-logs"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU utilization is above 80%"

  dimensions = {
    ClusterName = "${var.project_name}-${var.environment}"
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS memory utilization is above 80%"

  dimensions = {
    ClusterName = "${var.project_name}-${var.environment}"
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization is above 80%"

  dimensions = {
    DBInstanceIdentifier = "${var.project_name}-${var.environment}"
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}
