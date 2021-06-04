resource "aws_kms_key" "application" {
  description         = "A key to encrypt sensitive data in application"
  enable_key_rotation = true
  tags = {
    Group       = var.project
    Environment = var.env
  }
}
