#======================================
# elasticache cluster
#======================================
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.env}-${var.project}"
  engine               = "redis"
  engine_version       = "5.0.4"
  node_type            = "cache.t2.micro"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.main.id
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
}

#================================================
#elasticache parameter group
#================================================
resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.env}-${var.project}-redis-cache-params"
  family = "redis5.0"

  parameter {
    name  = "activerehashing"
    value = "yes"
  }

  parameter {
    name  = "notify-keyspace-events"
    value = "KEx"
  }
}

#============================================
#elasticache subnet group
#============================================
resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.env}${var.project}"
  description = "${var.env} CacheSubnetGroup"
  subnet_ids = [
    for subnet in aws_subnet.app_env_private :
    subnet.id
  ]
}
