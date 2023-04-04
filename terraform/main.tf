module "networking" {
  source = "./networking"
  region = var.region
  owner  = var.owner
}

module "database" {
  source                 = "./database"
  db_name                = var.db_name
  db_user                = var.db_user
  db_password            = var.db_password
  vpc_security_group_ids = [module.networking.db_sg_id]
  db_subnet_group_name   = module.networking.aws_db_subnet_group_name
  owner                  = var.owner
}

module "storage" {
  source = "./storage"
  owner  = var.owner
}

module "loadbalancing-internal" {
  source         = "./loadbalancing"
  name           = "db-lb"
  internal       = true
  port           = 8000
  vpc_id         = module.networking.vpc_id
  security_group = module.networking.db_lb_sg_id
  subnets        = module.networking.private_subnets_ids
  owner          = var.owner
}

module "loadbalancing-external" {
  source         = "./loadbalancing"
  name           = "external"
  internal       = false
  port           = 80
  vpc_id         = module.networking.vpc_id
  security_group = module.networking.ext_lb_sg_id
  subnets        = module.networking.public_subnets_ids
  owner          = var.owner
}

module "compute-db-apps" {
  source               = "./compute"
  app_name             = "db-app"
  instance_size        = var.instance_size
  subnets              = module.networking.private_subnets_ids
  key_name             = aws_key_pair.kp.id
  desired_capacity     = module.networking.az_count
  max_size             = module.networking.az_count
  min_size             = module.networking.az_count
  app_dependency       = module.database.db
  app_sg               = module.networking.db_app_sg_id
  iam_instance_profile = null
  tg_arn               = module.loadbalancing-internal.tg_arn
  owner                = var.owner
  user_data = base64encode(
    templatefile(
      "${path.root}/userdata/db_app_userdata.sh.tftpl",
      {
        db_host     = module.database.db_address
        db_port     = module.database.db_port
        db_user     = var.db_user
        db_password = var.db_password
        db_name     = var.db_name
      }
    )
  )
}

module "compute-s3-apps" {
  source               = "./compute"
  app_name             = "s3-app"
  instance_size        = var.instance_size
  subnets              = module.networking.private_subnets_ids
  key_name             = aws_key_pair.kp.id
  desired_capacity     = 2 * module.networking.az_count
  max_size             = 3 * module.networking.az_count
  min_size             = 1 * module.networking.az_count
  app_dependency       = null
  app_sg               = module.networking.s3_app_sg_id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tg_arn               = module.loadbalancing-external.tg_arn
  owner                = var.owner
  user_data = base64encode(
    templatefile(
      "${path.root}/userdata/s3_app_userdata.sh.tftpl",
      {
        db_app_host    = module.loadbalancing-internal.dns_name
        s3_bucket_name = module.storage.bucket_name
      }
    )
  )
}

resource "aws_instance" "bastion" {
  count           = 1
  ami             = module.compute-s3-apps.ec2_ami_id
  instance_type   = var.instance_size
  subnet_id       = module.networking.public_subnets_ids[count.index]
  security_groups = [module.networking.public_sg_id]
  key_name        = aws_key_pair.kp.id
  tags = {
    Name  = join("-", [var.owner, "bastion", (count.index + 1)])
    Owner = var.owner
  }
}
