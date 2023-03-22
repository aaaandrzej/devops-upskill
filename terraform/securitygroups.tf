resource "aws_security_group" "public" {
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
  description = "Allow 8000 inbound traffic from anywhere (temp!) and SSH from bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  ingress {
    description = "8000 from anywhere (temp!)"
    from_port   = 8000
    to_port     = 8000
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
    Name  = "${var.owner}-s3-app-sg"
    Owner = var.owner
  }
}

resource "aws_security_group" "db" {
  description = "Allow 3306 inbound traffic from db app"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "3306 from db app"
    from_port       = 3306 # consider using aws_db_instance.default.port but would need waiting for db
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
    Name  = "${var.owner}-db-lg-sg"
    Owner = var.owner
  }
}