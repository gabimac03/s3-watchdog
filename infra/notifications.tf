# --- Tópico de alertas ---
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

# Suscripción por email (confirmala desde tu correo)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- Regla de EventBridge: cuando una regla pasa a NON_COMPLIANT ---
resource "aws_cloudwatch_event_rule" "config_noncompliant" {
  name        = "${var.project}-config-noncompliant"
  description = "Alert when Config rule becomes NON_COMPLIANT"
  event_pattern = jsonencode({
    "source": ["aws.config"],
    "detail-type": ["Config Rules Compliance Change"],
    "detail": { "newEvaluationResult": { "complianceType": ["NON_COMPLIANT"] } }
  })
}

# Objetivo: enviar ese evento al SNS de alertas
resource "aws_cloudwatch_event_target" "to_sns" {
  rule      = aws_cloudwatch_event_rule.config_noncompliant.name
  target_id = "sns"
  arn       = aws_sns_topic.alerts.arn
}
