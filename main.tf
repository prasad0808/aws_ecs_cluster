module "aws_vpc" {
  source = "./aws-vpc-module"

  region             = "us-east-1"
  vpc_cidr           = "10.0.0.0/16"
  rds_allowed_cidr_blocks = ["10.0.1.0/24","10.0.2.0/24"]
  public_subnet_cidr = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  availability_zone  = "us-east-1a"
  vpc_id = module.aws_vpc.vpc_id
}

module "ecs_cluster" {
  source = "./ecs-ec2-module"

  cluster_name        = "my-ecs-cluster"
  ecs_instance_ami    = "ami-0961520434be05c63" # Use an appropriate ECS-optimized AMI ID for your region
  instance_type       = "t2.micro"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  alb_target_group_arn = "arn:aws:elasticloadbalancing:region:account-id:targetgroup/target-group-name/..."
  container_name = "your-container-name"
  desired_count = 2
  container_memory = 512
  container_cpu        = 256
  container_image      = "your-container-image-url"
  task_family = "your-task-family-name"
  container_port       = 8080
  service_name         = "your-service-name"
  private_subnet_ids  = module.aws_vpc.private_subnet_ids
  ecs_security_group_id = module.aws_vpc.ecs_security_group_id
  port_mappings = [
    {
      container_port = 80
      host_port      = 80
    },
    {
      container_port = 8080
      host_port      = 8080
    }
    # Add more port mappings as needed
  ]
}


module "aws_alb" {
  source = "./aws-alb-module"

  alb_name                   = "my-app-alb"
  internal                   = false
  security_groups            = [module.aws_vpc.alb_security_group_id]
  subnet_ids                 = module.aws_vpc.public_subnet_ids
  enable_deletion_protection = false
  tags                       = {"Name" = "my-app-alb"}

  target_group_name          = "my-app-tg"
  target_group_port          = 80
  target_group_protocol      = "HTTP"
  vpc_id                     = module.aws_vpc.vpc_id

  health_check_healthy_threshold   = 3
  health_check_unhealthy_threshold = 3
  health_check_timeout             = 5
  health_check_path                = "/"
  health_check_protocol            = "HTTP"
  health_check_interval            = 30
  health_check_matcher             = "200"

  listener_port     = 80
  listener_protocol = "HTTP"
}

module "aws_rds_mysql" {
  source = "./aws-rds-mysql-module"

  allocated_storage    = 20
  storage_type         = "gp2"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "mydbname"
  db_username          = "admin"
  db_password          = "securepassword"
  parameter_group_name = "default.mysql8.0"
  vpc_security_group_id = module.aws_vpc.aws_rds_sg
  subnet_ids            = module.aws_vpc.private_subnet_ids
  vpc_id               = module.aws_vpc.vpc_id
  allowed_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
}

module "ecr_repository" {
  source          = "./ecr-module"
  repository_name = "my-nodejs-app-repo"
}
