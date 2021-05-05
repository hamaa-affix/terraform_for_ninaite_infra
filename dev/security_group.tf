#====================================
#security_group for web
#====================================
resource "aws_security_group" "web" {
  vpc_id      = aws_vpc.app.id
  name        = "${var.dev}-${var.project}-web"
  description = "security_group for web"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.dev}_${var.project}-web-security_group"
  }
}

#====================================
#security_group for alb
#====================================
resource "aws_security_group" "alb" {
  vpc_id      = aws_vpc.app.id
  name        = "${var.dev}-${var.project}-alb"
  description = "security_group for web"

  ingress {
    from_port   = 433
    to_port     = 433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.dev}_${var.project}-alb-security_group"
  }
}

#====================================
#security_group for rds
#====================================
resource "aws_security_group" "rds" {
  vpc_id      = aws_vpc.app.id
  name        = "${var.dev}-${var.project}-rds"
  description = "security_group for web"

  ingress {
    from_port      = 3306
    to_port        = 3306
    protocol       = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
    security_group = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.dev}_${var.project}-rds-security_group"
  }
}
