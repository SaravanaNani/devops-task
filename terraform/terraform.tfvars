aws_region     = "ap-south-1"
project        = "devops-task"
docker_repo    = "saravana2002/devops-task"
image_tag      = "${BUILD_NUMBER}"
container_port = 3000
health_path    = "/"
cpu            = 256
memory         = 512
