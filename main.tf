resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name  = "aszulc-vpc"
    Owner = "aszulc"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name  = "aszulc-public-subnet-a"
    Owner = "aszulc"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name  = "aszulc-public-subnet-b"
    Owner = "aszulc"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false
  tags = {
    Name  = "aszulc-private-subnet-a"
    Owner = "aszulc"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.32.0/20"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false
  tags = {
    Name  = "aszulc-private-subnet-b"
    Owner = "aszulc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name  = "aszulc-igw"
    Owner = "aszulc"
  }
}

resource "aws_eip" "a" {
  vpc = true
  tags = {
    Name  = "aszulc-eip-a"
    Owner = "aszulc"
  }
}

resource "aws_eip" "b" {
  vpc = true
  tags = {
    Name  = "aszulc-eip-b"
    Owner = "aszulc"
  }
}

resource "aws_nat_gateway" "a" {
  allocation_id     = aws_eip.a.id
  subnet_id         = aws_subnet.public_subnet_a.id
  connectivity_type = "public"
  tags = {
    Name  = "aszulc-natgw-a"
    Owner = "aszulc"
  }
  # not sure if igw dependency is required
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "b" {
  allocation_id     = aws_eip.b.id
  subnet_id         = aws_subnet.public_subnet_b.id
  connectivity_type = "public"
  tags = {
    Name  = "aszulc-natgw-b"
    Owner = "aszulc"
  }
  # not sure if igw dependency is required
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public-rt-a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "aszulc-public-rt-a"
  Owner = "aszulc" }
}

resource "aws_route_table" "public-rt-b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "aszulc-public-rt-b"
  Owner = "aszulc" }
}

resource "aws_route_table" "private-rt-a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.a.id
  }

  tags = {
    Name = "aszulc-private-rt-a"
    Owner = "aszulc" }
}

resource "aws_route_table" "private-rt-b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.b.id
  }

  tags = {
    Name = "aszulc-private-rt-b"
  Owner = "aszulc" }
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public-rt-a.id
}
resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public-rt-b.id
}
resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private-rt-a.id
}
resource "aws_route_table_association" "private-b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private-rt-b.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-west-2.s3"

  tags = {
    Name  = "aszulc-vpc-endpoint-s3"
    Owner = "aszulc"
  }
}

resource "aws_vpc_endpoint_route_table_association" "a" {
  route_table_id  = aws_route_table.private-rt-a.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "b" {
  route_table_id  = aws_route_table.private-rt-b.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_s3_bucket" "main" {
  bucket = "aszulc-s3-2"
  tags = {
    Name  = "aszulc-s3-2"
    Owner = "aszulc"
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

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet_a.id
  #  security_groups = []
  #  iam_instance_profile = ""

  tags = {
    Name = "aszulc-bastion"
    Owner = "aszulc"
  }
}

resource "aws_instance" "private-ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.private_subnet_a.id
  #  security_groups = []
  #  iam_instance_profile = ""
  #  user_data = ""

  tags = {
    Name = "aszulc-private-ec2"
    Owner = "aszulc"
  }
}