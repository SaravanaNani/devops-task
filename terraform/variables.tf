variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "docker_repo" {
  description = "Docker repository for ECS"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "health_path" {
  description = "Health check path for ALB"
  type        = string
}

variable "cpu" {
  description = "CPU units for ECS task"
  type        = number
}

variable "memory" {
  description = "Memory for ECS task"
  type        = number
}

variable "min_capacity" {
  description = "Minimum ECS task count for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum ECS task count for auto-scaling"
  type        = number
  default     = 3
}
