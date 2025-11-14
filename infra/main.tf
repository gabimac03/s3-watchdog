terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# --- Rol para que AWS Config pueda auditar ---
resource "aws_iam_role" "config_role" {
  name               = "${var.project}-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_trust.json
}

data "aws_iam_policy_document" "config_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service", identifiers = ["config.amazonaws.com"] }
  }
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# --- Bucket para logs de AWS Config ---
resource "random_id" "suffix" { byte_length = 3 }

resource "aws_s3_bucket" "config_logs" {
  bucket        = "${var.project}-config-logs-${random_id.suffix.hex}"
  force_destroy = true
}

# --- Encender AWS Config y grabar todo ---
resource "aws_config_configuration_recorder" "this" {
  name     = "default"
  role_arn = aws_iam_role.config_role.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true
}

# --- Reglas administradas de S3 (prohibir público) ---
resource "aws_config_config_rule" "s3_public_read" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "s3_public_write" {
  name = "s3-bucket-public-write-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
}

resource "aws_config_config_rule" "s3_policy_public_write" {
  name = "s3-bucket-policy-public-write-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_POLICY_PUBLIC_WRITE_PROHIBITED"
  }
}
