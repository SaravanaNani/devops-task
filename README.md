# DevOps CI/CD Pipeline Setup with Jenkins, Terraform, and AWS ECS

This project demonstrates a full CI/CD pipeline using **Jenkins**, **Terraform**, **Docker**, and **AWS ECS**, with proper role-based access, CloudWatch monitoring, and AutoScaling.

---

## Prerequisites

1. **Jenkins VM Setup**

   We have created a Jenkins VM using Ubuntu and installed required dependencies:

   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y openjdk-17-jdk docker.io curl git
   java -version

   # Jenkins installation
   curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
   echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
   sudo apt update
   sudo apt install -y jenkins
   sudo systemctl enable jenkins
   sudo systemctl start jenkins
   jenkins --version  # 2.516.2
   ```

   Add current user to Docker group to allow Docker commands without sudo:

   ```bash
   sudo usermod -aG docker $USER
   sudo systemctl enable docker
   sudo systemctl start docker
   ```

2. **IAM Role: `jenkins-terraform-role`**

   The Jenkins VM is attached to a role with both **AWS managed** and **custom policies** for CI/CD operations.

   **Managed Policies:**

   * AmazonEC2FullAccess
   * AmazonECS\_FullAccess
   * AmazonS3FullAccess
   * AutoScalingFullAccess
   * IAMFullAccess

   **Custom Policies:**

   * **JenkinsTerraformCloudWatchPolicy**

     ```json
     {
         "Version": "2012-10-17",
         "Statement": [
             {
                 "Effect": "Allow",
                 "Action": [
                     "logs:CreateLogGroup",
                     "logs:CreateLogStream",
                     "logs:PutLogEvents",
                     "logs:PutRetentionPolicy",
                     "logs:ListTagsForResource",
                     "logs:DeleteLogGroup"
                 ],
                 "Resource": "*"
             }
         ]
     }
     ```

   * **CustomECSApplicationAutoScalingPolicy**

     ```json
     {
         "Version": "2012-10-17",
         "Statement": [
             {
                 "Effect": "Allow",
                 "Action": [
                     "application-autoscaling:RegisterScalableTarget",
                     "application-autoscaling:DeregisterScalableTarget",
                     "application-autoscaling:PutScalingPolicy",
                     "application-autoscaling:DeleteScalingPolicy",
                     "application-autoscaling:DescribeScalableTargets",
                     "application-autoscaling:DescribeScalingPolicies",
                     "application-autoscaling:DescribeScalingActivities",
                     "application-autoscaling:ListTagsForResource",
                     "ecs:UpdateService",
                     "ecs:DescribeServices",
                     "cloudwatch:PutMetricAlarm",
                     "cloudwatch:DeleteAlarms",
                     "cloudwatch:DescribeAlarms"
                 ],
                 "Resource": "*"
             }
         ]
     }
     ```

---

## Jenkins Docker Agent

We use a **custom Docker container** as a Jenkins agent to standardize the CI/CD environment.

**Dockerfile Highlights:**

```dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openjdk-17-jdk curl git unzip python3 python3-pip docker.io nodejs npm sudo ssh

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH:/workspace/node_modules/.bin"

ARG TERRAFORM_VERSION=1.6.0
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

RUN useradd -m -d /var/lib/jenkins -s /bin/bash jenkins \
    && echo 'jenkins:jenkins' | chpasswd \
    && echo 'jenkins ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /workspace
USER jenkins
CMD ["bash"]
```

* **Purpose:** Provides a reproducible build environment including Java, Node.js, Python, Terraform, Docker, and AWS CLI.
* **Docker Agent Image Workflow:**

  1. Build the agent image locally:

     ```bash
     docker build -t saravana2002/jenkins-agent:latest .
     ```
  2. Push the image to Docker Hub:

     ```bash
     docker push saravana2002/jenkins-agent:latest
     ```
  3. Use the image in Jenkins pipeline as agent:

     ```groovy
     agent {
         docker {
             image 'saravana2002/jenkins-agent:latest'
             args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
         }
     }
     ```

---

## Terraform Infrastructure

The pipeline uses **Terraform** to provision:

* VPC, subnets, and default security groups
* Internet Gateway & Route Tables
* ECS Cluster and Task Definition
* Application Load Balancer with Target Group
* CloudWatch Log Group for ECS logs
* AutoScaling Policies for ECS service

**CloudWatch & AutoScaling:**

* ECS tasks are configured to push logs to CloudWatch.
* AutoScaling monitors ECS metrics and scales the service based on CPU/Memory or custom CloudWatch alarms.

---

## Jenkins CI/CD Pipeline

Pipeline stages:

1. **Checkout** – Pulls code from GitHub.
2. **Build & Test** – Installs dependencies and runs unit tests.
3. **Terraform** – Initializes, plans, applies, or destroys infrastructure based on parameters.
4. **Build Docker Image** – Builds Docker image with `latest` tag.
5. **Push to DockerHub** – Pushes Docker image to DockerHub for agent use.
6. **Deploy to ECS** – Updates ECS service forcing a new deployment.
7. **Fetch ALB DNS** – Outputs the ALB DNS URL for verification.

**Webhooks:**

* GitHub webhooks trigger the pipeline automatically when code changes are pushed to the repository.

---

## Summary

* Jenkins VM with attached **IAM role** allows full CI/CD operations.
* Docker agent ensures reproducible environment for Terraform, Docker, and AWS commands.
* CloudWatch collects ECS logs; AutoScaling manages ECS service scaling.
* CI/CD pipeline is fully automated, triggered by GitHub commits or manual runs.

---
