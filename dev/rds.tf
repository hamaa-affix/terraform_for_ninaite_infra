#============================
#aurora cluster
#============================
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier              = "${var.env}-${var.project}-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = "5.7.mysql_aurora.2.07.2"
  database_name                   = var.project
  master_username                 = var.project
  master_password                 = var.rds_password
  backup_retention_period         = 1
  preferred_backup_window         = "18:00-18:30"
  preferred_maintenance_window    = "sun:18:30-sun:19:00"
  db_subnet_group_name            = aws_db_subnet_group.main.id
  vpc_security_group_ids          = [aws_security_group.aurora.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.id
  final_snapshot_identifier       = "${var.project}-${var.env}-aurora-cluster"
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  deletion_protection             = true
}

#===================================
#aurora cluster subnet group
#===================================
resource "aws_db_subnet_group" "main" {
  name        = "${var.env}-${var.project}"
  description = "${var.env}-subnet grupe"
  subnet_ids = [
    for subnet in aws_subnet.app_env_private :
    subnet.id
  ]

  tags = {
    Name = "${var.env} DB subnet group"
  }
}

#======================================================================================
#aws aurora instance master
#======================================================================================
resource "aws_rds_cluster_instance" "aurora_cluster_instance" {
  count                   = 1
  cluster_identifier      = aws_rds_cluster.aurora_cluster.id
  identifier              = "${var.env}-${var.project}-aurora-instance-${count.index + 1}"
  engine                  = "aurora-mysql"
  instance_class          = "db.t3.medium"
  db_parameter_group_name = aws_db_parameter_group.main.name
  db_subnet_group_name    = aws_db_subnet_group.main.name
  publicly_accessible     = false

  tags = {
    Name        = "${var.env}-${var.project}-${count.index}"
    Group       = var.project
    ManagedBy   = "terraform"
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [instance_class]
  }
}

#======================================================================================
#aws aurora instance replica
#======================================================================================
resource "aws_rds_cluster_instance" "aurora_cluster_instance_reader" {
  count                   = 1
  cluster_identifier      = aws_rds_cluster.aurora_cluster.id
  identifier              = "${var.env}-${var.project}-aurora-instance-${count.index + 1}-reader"
  engine                  = "aurora-mysql"
  instance_class          = "db.t3.medium"
  db_parameter_group_name = aws_db_parameter_group.main.name
  db_subnet_group_name    = aws_db_subnet_group.main.name
  publicly_accessible     = false
  depends_on              = [aws_rds_cluster_instance.aurora_cluster_instance]


  tags = {
    Name        = "${var.env}-${var.project}-${count.index}"
    Group       = var.project
    ManagedBy   = "terraform"
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [instance_class]
  }
}

#===============================================
#cluster parameter group
#===============================================
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.env}-${var.project}-aurora-pg"
  family      = "aurora-mysql5.7"
  description = "RDS parameter group for ${var.project}"

  #mysql charset
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  lifecycle {
    ignore_changes = [parameter]
  }
}

#================================================
#db parameter group
#================================================
resource "aws_db_parameter_group" "main" {
  name        = "${var.env}-${var.project}-pg"
  family      = "aurora-mysql5.7"
  description = "RDS parameter group for ${var.env}"

  parameter {
    name  = "max_connections"
    value = "512"
  }

  parameter {
    name         = "slow_query_log"
    value        = 1
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "long_query_time"
    value        = 0.1
    apply_method = "pending-reboot"
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
}
