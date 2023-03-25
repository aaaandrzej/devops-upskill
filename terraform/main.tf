module "database" {
  source      = "./database"
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
  #  db_subnet_group_name   = module.networking.db_subnet_group_name[0]
  #  vpc_security_group_ids = [module.networking.db_security_group]
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  owner                  = var.owner
}

module "loadbalancing" {
  source                = "./loadbalancing"
  vpc_id                = aws_vpc.main.id
  db_apps_tg_count      = local.az_count
  db_apps_tg_target_ids = module.compute.db_apps_ids
  db_apps_sg            = aws_security_group.db_lb.id
  external_lb_sg        = aws_security_group.external_lb.id
  private_subnets       = aws_subnet.private_subnets[*].id
  public_subnets        = aws_subnet.public_subnets[*].id
  owner                 = var.owner
}

module "compute" {
  source          = "./compute"
  instance_size   = var.instance_size
  public_subnets  = aws_subnet.public_subnets[*].id
  private_subnets = aws_subnet.private_subnets[*].id
  key_name        = aws_key_pair.kp.id
  owner           = var.owner

  # bastions
  no_of_bastions = 1
  bastion_sg     = aws_security_group.public.id

  # db apps
  no_of_db_apps     = local.az_count
  db_app_dependency = module.database.db
  db_app_sg         = aws_security_group.db_app.id
  db_app_user_data = templatefile(
    "${path.module}/userdata/db_app_userdata.sh.tftpl",
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
  s3_app_sg            = aws_security_group.s3_app.id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  s3_tg_arn            = module.loadbalancing.s3_tg_arn
  s3_app_user_data = base64encode(
    templatefile(
      "${path.module}/userdata/s3_app_userdata.sh.tftpl",
      {
        db_app_host    = module.loadbalancing.db_lb_host
        s3_bucket_name = aws_s3_bucket.main.id
      }
    )
  )
}


