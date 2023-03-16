resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name  = "${var.owner}-vpc"
    Owner = var.owner
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = lookup(var.cidr_blocks, var.scope.public)[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name  = join("-", [var.owner, "public-subnet", ["a", "b"][count.index]])
    Owner = var.owner
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = lookup(var.cidr_blocks, var.scope.private)[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name  = join("-", [var.owner, "private-subnet", ["a", "b"][count.index]])
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
  count = local.az_count
  vpc = true
  tags = {
    Name  = join("-", [var.owner, "eip", ["a", "b"][count.index]])
    Owner = var.owner
  }
}

resource "aws_nat_gateway" "natgw" {
  count = local.az_count
  allocation_id     = aws_eip.eip[count.index].id
  subnet_id         = aws_subnet.public_subnets[count.index].id
  connectivity_type = "public"
  tags = {
    Name  = join("-", [var.owner, "natgw", ["a", "b"][count.index]])
    Owner = var.owner
  }
  # not sure if igw dependency is required
  depends_on = [aws_internet_gateway.gw]
}


resource "aws_route_table" "public-rt" {
  count = local.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name  = join("-", [var.owner, "public-rt", ["a", "b"][count.index]])
    Owner = var.owner
  }
}

resource "aws_route_table" "private-rt" {
  count = local.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw[count.index].id
  }

  tags = {
    Name  = join("-", [var.owner, "private-rt", ["a", "b"][count.index]])
    Owner = var.owner
  }
}

resource "aws_route_table_association" "public" {
  count = local.az_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public-rt[count.index].id
}

resource "aws_route_table_association" "private" {
  count = local.az_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private-rt[count.index].id
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
  count = local.az_count
  route_table_id  = aws_route_table.private-rt[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_s3_bucket" "main" {
  bucket = "${var.owner}-s3-${random_pet.random_pet.id}"
  tags = {
    Name  = "${var.owner}-s3-${random_pet.random_pet.id}"
    Owner = var.owner
  }
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# add security group allowing 22 from anywhere
# add pem keypair


resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnets[0].id
  #  security_groups = []
  #  iam_instance_profile = ""

  tags = {
    Name = "${var.owner}-bastion"
    Owner = var.owner
  }
}

resource "aws_instance" "private-ec2" {
  count = local.az_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.private_subnets[count.index].id
  #  security_groups = []
  #  iam_instance_profile = ""
  #  user_data = ""

  tags = {
    Name  = join("-", [var.owner, "private-ec2", ["a", "b"][count.index]])
    Owner = var.owner
  }
}