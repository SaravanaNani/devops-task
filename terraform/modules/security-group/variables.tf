variable "vpc_id" {}
variable "allowed_ports" {
  type = list(number)
}
variable "project_name" {
  default = "devops-task"
}
