#==========================
# VPC
#==========================
resource "aws_vpc" "app" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.env}-${var.project}-vpc"
  }
}
#==============================
# subnets
#==============================
resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.app.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.app.cidr_block, 8, count.index)

  tags = {
    Name = "${var.env}-${var.project}-public"
  }
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.app.id
  availability_zone = var.availability_zones[count.index]
  cidr_block        = cidrsubnet(aws_vpc.app.cidr_block, 8, count.index + length(aws_subnet.public))

  tags = {
    Name = "${var.env}-${var.project}-private"
  }
}

#======================================
# igw
#======================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "${var.env}-${var.project}-igw"
  }
}

#======================================
# route table 経路情報の格納
#======================================
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.app.id

  lifecycle {
        ignore_changes = [
            route,
        ]
    }

  tags = {
    Name = "${var.env}-${var.project}-main-routetable"
  }
}

#=====================================
# router  route情報の追加
#=====================================
resource "aws_route" "default_gw" {
  route_table_id          = aws_route_table.main.id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.main.id
}

#=========================================
# route table association subnetの関連ずけ
#=========================================
resource "aws_route_table_association" "public" {
  count           = 3
  subnet_id       = aws_subnet.public[count.index].id
  route_table_id  = aws_route_table.main.id
}

resource "aws_route_table_association" "private" {
  count           = 3
  subnet_id       = aws_subnet.private[count.index].id
  route_table_id  = aws_route_table.main.id
}
