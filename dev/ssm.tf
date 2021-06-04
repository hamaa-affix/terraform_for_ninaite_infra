resource "aws_ssm_parameter" "mysql_password" {
  name        = "/${var.project}/${var.env}/mysql_password"
  description = "The parameter for mysql master password"
  key_id      = aws_kms_key.application.key_id
  type        = "SecureString"
  value       = var.rds_password

  tags = {
    Group       = var.project
    Environment = var.env
  }
}
