This project implements a deliberately flawed cloud deployment pipeline on AWS in the Frankfurt (`eu-central-1`) region using Terraform, Jenkins, and Bash. It deploys a public-facing `infrastructureascode/hello-world` application and a Jenkins instance as ECS containers across two VPCs, leveraging AWS services like EC2, ECS, IAM, Route53, S3, CloudWatch, ECR, and SNS. The pipeline includes three subtle flaws that don’t impair core functionality, as required for peer review.

Architecture
 **VPCs**: 
  - App: `10.40.0.0/16` (2 public, 2 private subnets).
  - Jenkins: `10.41.0.0/16` (2 public, 2 private subnets).
  - Peered for communication.
 **ECS Clusters**:
  - App: 2 `t3.micro` instances, 2 `hello-world` containers.
  - Jenkins: 1 `t3.micro` instance, 1 `jenkins/jenkins:lts` container.
 **ALBs**: Public-facing, currently HTTP (port 80) due to no domain (HTTPS planned).
 **Pipeline**: Jenkins builds `hello-world` from GitHub, pushes to ECR, deploys to ECS.
 **Logging**: S3 bucket for ALB/ECS logs, exported via Lambda.
 **Monitoring**: Route53 health checks, CloudWatch alarms (cost, 5xx, health).

-  Using HTTP (port 80) due to no domain; HTTPS requires a domain for ACM compliance
