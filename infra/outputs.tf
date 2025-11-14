output "sns_topic_arn"      { value = aws_sns_topic.alerts.arn }
output "config_logs_bucket" { value = aws_s3_bucket.config_logs.bucket }
