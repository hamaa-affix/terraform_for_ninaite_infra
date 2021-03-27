resource "aws_vpc" "app" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.env}-${var.project}-vpc"
  }
}
