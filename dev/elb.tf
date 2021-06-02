#========================
#elb
#=======================
resource "aws_lb" "web" {
  name            = "${var.env}-${var.project}-web-alb"
  internal        = false
  security_groups = [aws_security_group.alb.id]
  subnets = [
    for subnet in aws_subnet.app_env_public :
    subnet.id
  ]

  access_logs {
    bucket = aws_s3_bucket.alb_logs.bucket
    prefix = var.project
  }

  tags = {
    Group      = var.project
    Enviroment = var.env
  }
}


#================================
#target group
#================================

resource "aws_alb_target_group" "web" {
  name        = "${var.env}-${var.project}-tg-web"
  target_type = "ip"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_env.id

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 600
    enabled         = false
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    path                = "/healthcheck"
  }

  tags = {
    Group      = var.project
    Enviroment = var.env
  }
}

#======================================
#listener
#======================================
resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.web_443.arn

  condition {
    host_header {
      values = [
        var.domain
      ]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.web.arn
  }
}

resource "aws_lb_listener" "web_443" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.web.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      status_code  = 404
      message_body = "<html><head><title>404 Not Found</title></head><body><h1>Not Found</h1><hr><address>Apache/2.2.31</address></body></html>"
    }
  }
}
