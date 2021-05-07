resource "aws_db_instance" "main" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "${var.env}-${var.project}-rds"
  username             = ${var.project}
  password             = var.rds_password
  parameter_group_name = "default.mysql5.7"
  backup_retention_period = 1
  backup_window ="03:00-03:30"
  db_subnet_group_name = aws_db_subnet_group.main.id
  delete_automated_backups            = true
  deletion_protection                 = false
  skip_final_snapshot  = true
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
}

resource "aws_db_subnet_group" "main" {
  name = "${var.env}-${var.project}-subnet for rds"
  description = "${var.env}-subnet grupe"
  subnet_ids = [
    for subnet in aws_subnet.app_env_public :
    subnet.id
  ]

  tags = {
    Name = "${var.env} DB subnet group"
  }
}

resource "aws_db_parameter_group" "main" {
  name = "rds-pg"
  family = "mysql5.7"
  description = "RDS parameter group for ${var.env}"
  parameter {
    name = "slow_query_log"
    value = 1
  }

  parameter {
    name         = "log_output"
    value        = "file"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "query_cache_type"
    value        = 1
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "general_log"
    value        = 1
    apply_method = "pending-reboot"
}
