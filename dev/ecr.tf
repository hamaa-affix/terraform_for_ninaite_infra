resource "aws_ecr_repository" "app" {
  name = "${var.env}/${var.project}/app"
}

resource "aws_ecr_repository" "nginx" {
  name = "${var.env}/${var.project}/nginx"
}
