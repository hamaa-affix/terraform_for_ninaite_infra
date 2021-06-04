#========================================
# cluster
#========================================
resource "aws_ecs_cluster" "app_cluster" {
  name               = "${var.env}-${var.project}"
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 0
  }

  default_capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

#=================================
#service
#=================================
resource "aws_ecs_service" "app" {
  name                               = "app"
  cluster                            = aws_ecs_cluster.app_cluster.id
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  platform_version                   = "1.4.0"

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 0
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.web.arn
    container_name   = "nginx"
    container_port   = 80
  }

  network_configuration { #network設定
    subnets = [
      for subnet in aws_subnet.app_env_public :
      subnet.id
    ]
    security_groups  = [aws_security_group.web.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      capacity_provider_strategy,
      task_definition,
      desired_count,
    ]
  }
}

resource "aws_ecs_service" "cron" {
  name                               = "cron"
  cluster                            = aws_ecs_cluster.app_cluster.id
  task_definition                    = aws_ecs_task_definition.cron.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  platform_version                   = "1.4.0"

  capacity_provider_strategy {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 0
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets = [
      aws_subnet.app_cron_private.id
    ]
    security_groups  = [aws_security_group.web.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }
}

resource "aws_ecs_service" "queue" {
  name                               = "queue"
  cluster                            = aws_ecs_cluster.app_cluster.id
  task_definition                    = aws_ecs_task_definition.queue.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  platform_version                   = "1.4.0"

  capacity_provider_strategy {
    base              = 1
    capacity_provider = "FARGATE"
    weight            = 0
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets = [
      aws_subnet.app_cron_private.id
    ]
    security_groups  = [aws_security_group.web.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }
}

#=========================================
# auto scaling
#=========================================
resource "aws_appautoscaling_target" "app" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 3

  lifecycle {
    ignore_changes = [
      max_capacity,
      min_capacity,
    ]
  }
}

resource "aws_appautoscaling_policy" "app_scale_out" {
  name               = "scale-out"
  service_namespace  = "ecs"
  policy_type        = "StepScaling"
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 3
    }
  }

  depends_on = [aws_appautoscaling_target.app]

  lifecycle {
    ignore_changes = [step_scaling_policy_configuration]
  }
}

resource "aws_appautoscaling_policy" "app_scale_in" {
  name               = "scale-in"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.app]

  lifecycle {
    ignore_changes = [step_scaling_policy_configuration]
  }
}

#=======================================
#task definition
#=======================================
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.env}-${var.project}-app"
  container_definitions    = file("files/task-definitions/app.json")
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_service_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_task_definition" "migrate" {
  family                   = "${var.env}-${var.project}-migrate"
  container_definitions    = file("files/task-definitions/migrate.json")
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_service_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_task_definition" "cron" {
  family                   = "${var.env}-${var.project}-cron"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_service_role.arn
  container_definitions    = file("files/task-definitions/cron.json")
}

resource "aws_ecs_task_definition" "queue" {
  family                   = "${var.env}-${var.project}-queue"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_service_role.arn
  container_definitions    = file("files/task-definitions/queue.json")
}
