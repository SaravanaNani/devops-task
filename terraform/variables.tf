variable "aws_region" {}
variable "project" {}
variable "docker_repo" {}
variable "image_tag" {
  description = "Docker image tag for ECS task"
  default     = "latest"   # any default tag
}

variable "container_port" {}
variable "health_path" {}
variable "cpu" {}
variable "memory" {}
