resource "aws_vpc" "main" {
  count            = var.public ? 1 : 0
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  tags = {
    Name  = "${var.owner}-vpc"
    Owner = var.owner
  }
}

resource "aws_subnet" "subnets" {
  for_each                = toset(var.availability_zones)
  vpc_id                  = var.public ? aws_vpc.main[0].id : var.main_vpc_id
  cidr_block              = lookup(var.cidr_blocks, var.public ? var.scope.public : var.scope.private)[index(var.availability_zones, each.key)]
  availability_zone       = each.key
  map_public_ip_on_launch = var.public
  tags = {
    Name  = join("-", [var.owner, var.public ? "public" : "private", each.key])
    Owner = var.owner
  }
}

resource "aws_db_subnet_group" "default" {
  count      = var.public ? 0 : 1
  name       = "main"
  subnet_ids = [for k, v in aws_subnet.subnets : v.id]

  tags = {
    Name  = "${var.owner}-private-db-subnet-group"
    Owner = var.owner
  }
}

resource "aws_internet_gateway" "gw" {
  count  = var.public ? 1 : 0
  vpc_id = aws_vpc.main[0].id
  tags = {
    Name  = "${var.owner}-igw"
    Owner = var.owner
  }
}

resource "aws_eip" "eip" {
  for_each = var.public ? toset([]) : toset(var.availability_zones)
  vpc      = true
  tags = {
    Name  = join("-", [var.owner, "eip", each.key])
    Owner = var.owner
  }
}

resource "aws_nat_gateway" "natgw" {
  for_each          = var.public ? toset([]) : toset(var.availability_zones)
  allocation_id     = aws_eip.eip[each.key].id
  subnet_id         = var.public_subnets[index(var.availability_zones, each.key)]
  connectivity_type = "public"
  tags = {
    Name  = join("-", [var.owner, "natgw", each.key])
    Owner = var.owner
  }
  # docs suggest igw dependency here but it doesn't seem to be required but causes extra complexity
  #  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
  #  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "rt" {
  for_each = toset(var.availability_zones)
  vpc_id   = var.public ? aws_vpc.main[0].id : var.main_vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = var.public ? aws_internet_gateway.gw[0].id : null
    nat_gateway_id = var.public ? null : aws_nat_gateway.natgw[each.key].id
  }
  tags = {
    Name  = join("-", [var.owner, var.public ? "public" : "private", "rt", each.key])
    Owner = var.owner
  }
}

resource "aws_route_table_association" "main" {
  for_each       = toset(var.availability_zones)
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.rt[each.key].id
}

resource "aws_vpc_endpoint" "s3" {
  count        = var.public ? 0 : 1
  vpc_id       = var.main_vpc_id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Name  = "${var.owner}-vpc-endpoint-s3"
    Owner = var.owner
  }
}

resource "aws_vpc_endpoint_route_table_association" "vpce_rt_assoc" {
  for_each        = var.public ? toset([]) : toset(var.availability_zones)
  route_table_id  = aws_route_table.rt[each.key].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

resource "aws_security_group" "public" {
  count       = var.public ? 1 : 0
  name        = "public-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
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
    Name  = "${var.owner}-public-sg"
    Owner = var.owner
  }
}

resource "aws_security_group" "db_app" {
  count       = var.public ? 0 : 1
  name        = "db-app-sg"
  description = "Allow 8000 inbound traffic from db load balancer and SSH from bastion"
  vpc_id      = var.main_vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.public_sg_id]
  }

  ingress {
    description     = "8000 from db lb"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.db_lb[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.owner}-db-app-sg"
    Owner = var.owner
  }
}

resource "aws_security_group" "s3_app" {
  count       = var.public ? 0 : 1
  name        = "s3-app-sg"
  description = "Allow 8000 inbound traffic from external load balancer and SSH from bastion"
  vpc_id      = var.main_vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.public_sg_id]
  }

  ingress {
    description     = "8000 from external load balancer"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.external_lb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.owner}-s3-app-sg"
    Owner = var.owner
  }
}

resource "aws_security_group" "db" {
  count       = var.public ? 0 : 1
  name        = "db-sg"
  description = "Allow 3306 inbound traffic from db app"
  vpc_id      = var.main_vpc_id

  ingress {
    description     = "3306 from db app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.db_app[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.owner}-db-sg"
    Owner = var.owner
  }
}

resource "aws_security_group" "db_lb" {
  count       = var.public ? 0 : 1
  name        = "db-lb"
  description = "Allow 8000 inbound traffic from s3 apps"
  vpc_id      = var.main_vpc_id

  ingress {
    description     = "8000 from s3_app"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.s3_app[0].id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "${var.owner}-db-lb-sg"
    Owner = var.owner
  }
}

resource "aws_security_group" "external_lb" {
  count       = var.public ? 1 : 0
  name        = "external-lb"
  description = "Allow 80 inbound traffic from anywhere"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
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
    Name  = "${var.owner}-external-lb-sg"
    Owner = var.owner
  }
}