terraform {
  backend "s3" {
    bucket         = "adq-terraform-state"
    key            = "ecs/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }
}
