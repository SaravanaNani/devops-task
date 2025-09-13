
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

2. **S3 Bucket for Terraform State**

   Terraform uses a remote backend to store state for safe collaboration. Ensure you have created an **S3 bucket**
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "<your-terraform-state-bucket>"
       key            = "terraform.tfstate"
       region         = "ap-south-1"
     }
   }
   ```

3. **IAM Role: `jenkins-terraform-role`**

   The Jenkins VM is attached to a role with both **AWS managed** and **custom policies** for CI/CD operations.

   **Managed Policies:**

   * AmazonEC2FullAccess
   * AmazonECS\_FullAccess
   * AmazonS3FullAccess
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

RUN apt-get update && apt-get install -y     openjdk-17-jdk curl git unzip python3 python3-pip docker.io nodejs npm sudo ssh

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH:/workspace/node_modules/.bin"

ARG TERRAFORM_VERSION=1.6.0
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip     && unzip terraform.zip     && mv terraform /usr/local/bin/     && rm terraform.zip

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"     && unzip awscliv2.zip     && ./aws/install     && rm -rf awscliv2.zip aws

RUN useradd -m -d /var/lib/jenkins -s /bin/bash jenkins     && echo 'jenkins:jenkins' | chpasswd     && echo 'jenkins ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

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

* ECS tasks push logs to CloudWatch.  
* AutoScaling monitors ECS metrics and scales based on CPU/Memory or CloudWatch alarms.  

---

## Jenkins CI/CD Pipeline

Pipeline stages:

1. **Checkout** – Pulls code from GitHub.  
2. **Build & Test** – Installs dependencies and runs unit tests.  
3. **Terraform** – Initializes, plans, applies, or destroys infrastructure.  
4. **Build Docker Image** – Builds Docker image with `latest` tag.  
5. **Push to DockerHub** – Pushes Docker image to DockerHub for agent use.  
6. **Deploy to ECS** – Updates ECS service forcing a new deployment.  
7. **Fetch ALB DNS** – Outputs the ALB DNS URL for verification.  

**Webhooks:** GitHub webhooks trigger the pipeline automatically when code changes are pushed.

---

## Write-Up

### Challenges Faced & Resolutions

1. **CloudWatch Permission Issue**  
   *Issue:* Terraform plan failed due to missing CloudWatch permissions.  
   *Resolution:* Created `JenkinsTerraformCloudWatchPolicy` and attached to Jenkins IAM role.  

2. **ECS AutoScaling & Deployment Permissions**  
   *Issue:* ECS service updates and AutoScaling targets failed.  
   *Resolution:* Created `CustomECSApplicationAutoScalingPolicy` and attached to Jenkins role.  

3. **Docker Agent for Jenkins**  
   *Issue:* Needed consistent environment for builds, Terraform, and deployments.  
   *Resolution:* Built custom Docker agent with Java, Node.js, Python, Terraform, Docker, and AWS CLI.  

4. **Initial Deployment & Pipeline Validation**  
   *Issue:* Ensuring Docker image build, push, and ECS deployment worked correctly.  
   *Resolution:* Verified pipeline stages, GitHub webhook triggers, and confirmed deployed application via ALB URL.  

5. **Networking & Security Groups**  
   *Issue:* ECS tasks were not publicly accessible.  
   *Resolution:* Configured VPC, public subnets, and security groups to allow HTTP/HTTPS; ensured ALB routing to ECS targets.  

## Possible Improvements

1. **Branch-Based Deployments**  
   Automate deployments per branch (`dev` → staging, `main` → production) to support multiple environments.

2. **CI/CD Testing Enhancements**  
   Add automated **unit tests** for the Node.js application and integrate **SonarQube** for code quality checks and vulnerability scanning.

3. **Terraform State Management**  
   Currently using S3 backend; adding a **DynamoDB table for state locking** would prevent concurrent modifications during team collaboration.

4. **Secure ALB Traffic**  
   Enable **HTTPS** using **AWS ACM certificates** to encrypt traffic to the application.

5. **Monitoring & Alerts**  
   Create **CloudWatch dashboards** and configure alarms for ECS metrics (CPU, memory, etc.) for proactive monitoring.

6. **Infrastructure as Code Enhancements**  
   Modularize Terraform code and create **reusable modules** for VPC, ECS, ALB, and AutoScaling for better maintainability and scalability.

7. **Automated Rollbacks**  
   Implement automated rollback in the pipeline if deployment fails, allowing ECS tasks to revert to the previous stable version.

---

## Deployment Proof / Screenshot

*ALB URL:* `http://devops-task-alb-385987850.ap-south-1.elb.amazonaws.com/`  
<img width="1273" height="669" alt="image" src="https://github.com/user-attachments/assets/7b5fae1c-eddb-4e71-a9c8-9b69d1c164b7" />

