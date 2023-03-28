module "networking" {
  source             = "./networking"
  region             = var.region
  availability_zones = var.availability_zones
  owner              = var.owner
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

module "loadbalancing" {
  source                = "./loadbalancing"
  vpc_id                = module.networking.vpc_id
  db_apps_tg_count      = module.networking.az_count
  db_apps_tg_target_ids = module.compute.db_apps_ids
  db_lb_sg              = module.networking.db_lb_sg_id
  external_lb_sg        = module.networking.ext_lb_sg_id
  private_subnets       = module.networking.private_subnets_ids
  public_subnets        = module.networking.public_subnets_ids
  owner                 = var.owner
}

module "compute" {
  source          = "./compute"
  instance_size   = var.instance_size
  private_subnets = module.networking.private_subnets_ids
  public_subnets  = module.networking.public_subnets_ids
  key_name        = aws_key_pair.kp.id
  owner           = var.owner

  # bastions
  no_of_bastions = 1
  bastion_sg     = module.networking.public_sg_id

  # db apps
  no_of_db_apps     = module.networking.az_count
  db_app_dependency = module.database.db
  db_app_sg         = module.networking.db_app_sg_id
  db_app_user_data = templatefile(
    "${path.root}/userdata/db_app_userdata.sh.tftpl",
    {
      db_host     = module.database.db_address
      db_port     = module.database.db_port
      db_user     = var.db_user
      db_password = var.db_password
      db_name     = var.db_name
    }
  )

  # s3 apps
  no_of_s3_apps        = [2, 4, 6]
  s3_app_sg            = module.networking.s3_app_sg_id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  s3_tg_arn            = module.loadbalancing.s3_tg_arn
  s3_app_user_data = base64encode(
    templatefile(
      "${path.root}/userdata/s3_app_userdata.sh.tftpl",
      {
        db_app_host    = module.loadbalancing.db_lb_host
        s3_bucket_name = module.storage.bucket_name
      }
    )
  )
}


