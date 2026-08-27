# --- Observability: CloudWatch Alarms + SNS ---
#
# This file is intentionally NOT part of the initial commit to main.
# You'll add it yourself on a feature branch and open a PR for it,
# that's the actual lab exercise: proposing an infra change through
# the same review flow a real team uses.

resource "aws_sns_topic" "db_alerts" {
  name = "${var.project_name}-db-alerts"

  tags = {
    Project = var.project_name
  }
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.db_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alarms on the metrics that actually matter for a small Aurora Serverless v2
# cluster: connection saturation and ACU ceiling, both signal "about to have
# a bad time" before anything actually breaks.

resource "aws_cloudwatch_metric_alarm" "high_connections" {
  alarm_name          = "${var.project_name}-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "DatabaseConnections"
  namespace            = "AWS/RDS"
  period               = 60
  statistic            = "Average"
  threshold            = 50
  alarm_description    = "Triggers if connection count stays above 50 for 2 consecutive minutes"
  alarm_actions        = [aws_sns_topic.db_alerts.arn]
  ok_actions            = [aws_sns_topic.db_alerts.arn]

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.lab.cluster_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "acu_near_ceiling" {
  alarm_name          = "${var.project_name}-acu-near-ceiling"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 3
  metric_name          = "ServerlessDatabaseCapacity"
  namespace            = "AWS/RDS"
  period               = 60
  statistic            = "Average"
  threshold            = var.max_acu * 0.9
  alarm_description    = "Triggers when the cluster is running near its max ACU ceiling, a sign it may need max_acu raised"
  alarm_actions        = [aws_sns_topic.db_alerts.arn]
  ok_actions            = [aws_sns_topic.db_alerts.arn]

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.lab.cluster_identifier
  }
}
