# DevOps CI/CD Setup – Jenkins, Docker, Terraform, ECS

## Overview

This project demonstrates a full DevOps pipeline setup using Jenkins, Docker, Terraform, and AWS ECS. The goal was to automate infrastructure provisioning and application deployment with proper monitoring, scaling, and CI/CD triggers.

---

## Infrastructure Setup (Terraform)

We used Terraform to provision the AWS infrastructure:

- **VPC**: Created a default VPC with public subnets, internet gateway, and route tables.  
- **Security Groups**: Opened all ports for the Jenkins VM; ECS tasks security group and ALB security group configured.  
- **ECS Cluster & Service**: ECS cluster `devops-task-cluster` created, service `devops-task-service` deployed with Docker image.  
- **Load Balancer**: Application Load Balancer created for external access with listener and target group.  
- **CloudWatch Logs**: Created a log group `/ecs/devops-task` for ECS task logs with retention policies.  
- **AutoScaling**: Configured ECS service auto-scaling with CloudWatch metrics.

**Terraform Flow in Jenkins**:

1. Terraform `init` → initializes working directory.  
2. Terraform `plan` → generates execution plan, detects changes.  
3. Terraform `apply` → applies changes (creates/updates infra).  
4. Terraform `destroy` → destroys infra (optional).  
5. Manual approvals implemented in Jenkins pipeline before `apply` or `destroy`.

---

## Jenkins Setup

- Installed Jenkins (v2.516.2) on an Ubuntu VM.  
- Installed Docker on Jenkins VM and added user to `docker` group.  
- Jenkins uses **Docker containers as agents** to run builds and deployments. This ensures a clean and isolated environment for pipeline execution.

**Pipeline Features**:

1. **Checkout**: Pulls code from GitHub.  
2. **Build & Test**: Runs `npm install` and `npm test`.  
3. **Terraform**: Provisions infra with manual approvals for changes or destruction.  
4. **Docker Build & Push**: Builds Docker image tagged `latest` and pushes to DockerHub.  
5. **Deploy to ECS**: Forces ECS service to redeploy with new image.  
6. **Fetch ALB DNS**: Displays application URL in Jenkins console and build description.

---

## IAM Role & Policies

Jenkins VM assumes the role **`jenkins-terraform-role`** with attached policies:

### Custom Policies

**1. JenkinsTerraformCloudWatchPolicy**

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

**2. CustomECSApplicationAutoScalingPolicy**

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

### Attached Managed Policies

- `AmazonEC2FullAccess`  
- `AmazonECS_FullAccess`  
- `AmazonS3FullAccess`  
- `AutoScalingFullAccess`  
- `IAMFullAccess`  

This combination ensures Jenkins can provision infra, manage ECS deployments, configure AutoScaling, and send logs to CloudWatch.

---

## CloudWatch & AutoScaling

- ECS logs are sent to CloudWatch log group `/ecs/devops-task`.  
- AutoScaling policies ensure ECS service scales automatically based on CloudWatch metrics.  
- CloudWatch Alarms monitor ECS metrics and trigger scaling actions.

---

## Webhooks (CI/CD Trigger)

- GitHub webhooks can be configured to trigger Jenkins pipelines automatically on push/PR events.  
- Ensures full CI/CD automation without manual intervention.

---

## Summary

- Jenkins VM deployed with Docker and proper IAM role.  
- Terraform code provisions VPC, ECS, ALB, Security Groups, CloudWatch logs, and AutoScaling.  
- Jenkins pipeline handles build, test, Docker image push, and ECS deployment.  
- CloudWatch and AutoScaling are fully integrated.  
- Webhook integration supports automatic CI/CD triggers.

**Application is accessible via the ALB DNS displayed in Jenkins after deployment.**
