data "aws_availability_zones" "with" {
  state         = "available"
  exclude_names = ["${var.region}d", "${var.region}e"]
}

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  tags = {
    Name  = "${var.owner}-vpc"
    Owner = var.owner
  }
}

resource "aws_subnet" "public_subnets" {
  for_each                = toset(data.aws_availability_zones.with.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = lookup(var.cidr_blocks, var.scope.public)[index(data.aws_availability_zones.with.names, each.key)]
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = {
    Name  = join("-", [var.owner, "public-subnet", each.key])
    Owner = var.owner
  }
}

resource "aws_subnet" "private_subnets" {
  for_each                = toset(data.aws_availability_zones.with.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = lookup(var.cidr_blocks, var.scope.private)[index(data.aws_availability_zones.with.names, each.key)]
  availability_zone       = each.key
  map_public_ip_on_launch = false
  tags = {
    Name  = join("-", [var.owner, "private-subnet", each.key])
    Owner = var.owner
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [for k, v in aws_subnet.private_subnets : v.id]

  tags = {
    Name  = "${var.owner}-private-subnet-group"
    Owner = var.owner
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name  = "${var.owner}-igw"
    Owner = var.owner
  }
}

resource "aws_eip" "eip" {
  for_each = toset(data.aws_availability_zones.with.names)
  vpc      = true
  tags = {
    Name  = join("-", [var.owner, "eip", each.key])
    Owner = var.owner
  }
}

resource "aws_nat_gateway" "natgw" {
  for_each          = toset(data.aws_availability_zones.with.names)
  allocation_id     = aws_eip.eip[each.key].id
  subnet_id         = aws_subnet.public_subnets[each.key].id
  connectivity_type = "public"
  tags = {
    Name  = join("-", [var.owner, "natgw", each.key])
    Owner = var.owner
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public-rt" {
  for_each = toset(data.aws_availability_zones.with.names)
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name  = join("-", [var.owner, "public-rt", each.key])
    Owner = var.owner
  }
}

resource "aws_route_table" "private-rt" {
  for_each = toset(data.aws_availability_zones.with.names)
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw[each.key].id
  }

  tags = {
    Name  = join("-", [var.owner, "private-rt", each.key])
    Owner = var.owner
  }
}

resource "aws_route_table_association" "public" {
  for_each       = toset(data.aws_availability_zones.with.names)
  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public-rt[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = toset(data.aws_availability_zones.with.names)
  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private-rt[each.key].id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = {
    Name  = "${var.owner}-vpc-endpoint-s3"
    Owner = var.owner
  }
}

resource "aws_vpc_endpoint_route_table_association" "vpce_rt_assoc" {
  for_each        = toset(data.aws_availability_zones.with.names)
  route_table_id  = aws_route_table.private-rt[each.key].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_security_group" "public" {
  name        = "public-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

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
  name        = "db-app-sg"
  description = "Allow 8000 inbound traffic from db load balancer and SSH from bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  ingress {
    description     = "8000 from db lb"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.db_lb.id]
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
  name        = "s3-app-sg"
  description = "Allow 8000 inbound traffic from external load balancer and SSH from bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  ingress {
    description     = "8000 from external load balancer"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.external_lb.id]
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
  name        = "db-sg"
  description = "Allow 3306 inbound traffic from db app"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "3306 from db app"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.db_app.id]
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
  name        = "db-lb"
  description = "Allow 8000 inbound traffic from s3 apps"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "8000 from s3_app"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.s3_app.id]
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
  name        = "external-lb"
  description = "Allow 80 inbound traffic from anywhere"
  vpc_id      = aws_vpc.main.id

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