provider "aws" {
  region = "ap-south-1"
}

# VPC
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "10.0.0.0/16"
}

# Security Group
module "sg" {
  source        = "./modules/security-group"
  vpc_id        = module.vpc.vpc_id
  allowed_ports = [22, 80, 443]
}

# ECS Cluster
module "ecs_cluster" {
  source       = "./modules/ecs-cluster"
  cluster_name = "adq-ecs-cluster"
}

# ALB
module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  sg_id          = module.sg.sg_id
  alb_name       = "adq-alb"
}

# ECS Service + Task
module "ecs_service" {
  source               = "./modules/ecs-service"
  cluster_id           = module.ecs_cluster.cluster_id
  cluster_name         = module.ecs_cluster.cluster_name
  subnets              = module.vpc.public_subnets
  sg_id                = module.sg.sg_id
  container_port       = 3000
  desired_count        = 1
  alb_target_group_arn = module.alb.target_group_arn
  docker_image         = "saravana2002/devops-task:latest" # DockerHub image
}
