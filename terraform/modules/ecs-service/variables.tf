variable "cluster_id" {}
variable "cluster_name" {}
variable "subnets" { type = list(string) }
variable "sg_id" {}
variable "container_port" {}
variable "desired_count" { default = 1 }
variable "alb_target_group_arn" {}
variable "docker_image" {}
