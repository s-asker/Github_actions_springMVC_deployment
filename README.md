# Spring MVC Project Deployment with GitHub Actions and AWS

This project demonstrates the deployment of a Spring MVC application using **GitHub Actions** for CI/CD and **AWS** for infrastructure. The setup includes automated testing, Docker image building, deployment to AWS ECS (Elastic Container Service), and database management using AWS RDS (Relational Database Service).

---

## Table of Contents
1. [Introduction](#introduction)
2. [Project Overview](#project-overview)
3. [Prerequisites](#prerequisites)
4. [GitHub Actions Workflow](#github-actions-workflow)
5. [AWS Infrastructure Setup](#aws-infrastructure-setup)
6. [Terraform Configuration](#terraform-configuration)
7. [Dockerfile](#dockerfile)
8. [Security and Best Practices](#security-and-best-practices)
9. [Screenshots](#screenshots)

---

## Introduction

This project automates the deployment of a Spring MVC application using modern DevOps practices. The key components include:

- **GitHub Actions**: For continuous integration and deployment (CI/CD).
- **AWS ECR**: For storing Docker images.
- **AWS ECS**: For running the application in a containerized environment.
- **AWS RDS**: For hosting the MySQL database.
- **Terraform**: For infrastructure as code (IaC) to provision and manage AWS resources.

The goal is to create a seamless, secure, and scalable deployment pipeline for the Spring MVC application.

---

## Project Overview

The project is divided into the following main components:

### 1. **GitHub Actions Workflow**
   - **Source Code Testing**: Runs Maven tests and performs a SonarQube scan to ensure code quality.
   - **Build and Push to ECR**: Builds a Docker image and pushes it to AWS ECR.
   - **Deploy to ECS**: Deploys the Docker image to AWS ECS using Fargate.

### 2. **AWS Infrastructure**
   - **ECR Repository**: Stores Docker images.
   - **ECS Cluster and Service**: Manages the deployment and running of Docker containers.
   - **RDS Instance**: Hosts the MySQL database for the application.
   - **EC2 Instance**: Provides a client for accessing the RDS instance.
   - **IAM Roles and Policies**: Manages permissions for ECS tasks and other AWS resources.
   - **Security Groups**: Controls inbound and outbound traffic for EC2, RDS, and ECS resources.

### 3. **Terraform Configuration**
   - Terraform is used to define and provision the AWS infrastructure, including ECR, ECS, RDS, EC2, IAM roles, and security groups.

### 4. **Dockerfile**
   - A multi-stage Dockerfile is used to build the Spring MVC application and deploy it to a Tomcat server.

### 5. **Security and Best Practices**
   - Sensitive information is managed using GitHub secrets.
   - Code quality is ensured through SonarQube integration.
   - Infrastructure is managed as code using Terraform, ensuring consistency and reproducibility.

---

## Prerequisites

Before proceeding, ensure you have the following:

1. **GitHub Repository**: The Spring MVC application code should be hosted on GitHub.
2. **AWS Account**: An AWS account with the necessary permissions to create and manage ECR, ECS, RDS, EC2, and IAM resources.
3. **Terraform Installed**: Terraform should be installed on your local machine or CI/CD environment.
4. **Docker Installed**: Docker should be installed for building and pushing Docker images.
5. **SonarQube Account**: A SonarQube account for code quality scanning (optional but recommended).

---

## GitHub Actions Workflow

The GitHub Actions workflow automates the following steps:

1. **Clone Repository**: Clones the Spring MVC application code.
2. **Maven Testing**: Runs unit tests using Maven.
3. **Setup JDK 11**: Configures the Java environment.
4. **SonarQube Scan**: Performs a code quality scan using SonarQube.
5. **Build and Push to ECR**: Builds a Docker image and pushes it to AWS ECR.
6. **Deploy to ECS**: Deploys the Docker image to AWS ECS.

### GitHub Actions Workflow Code

```yaml
name: Spring MVC Project Deployment

on:
  push:
    branches:
      - main  # Trigger only for pushes to the 'main' branch
  workflow_dispatch:

env:
  REGION: us-east-2

jobs:
  SourceCode_Testing:
    runs-on: ubuntu-latest
    steps:
      - name: Clone source code from the repo
        uses: actions/checkout@v4.2.2

      - name: Maven Testing
        run: mvn test

      - name: Setup JDK11 for the workflow
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '11'

      - name: Setup SonarQube
        uses: warchant/setup-sonar-scanner@v7

      - name: SonarQube Scan
        run: |
          sonar-scanner \
            -Dsonar.host.url=${{ secrets.SONAR_URL }} \
            -Dsonar.login=${{ secrets.SONAR_TOKEN }} \
            -Dsonar.organization=${{ secrets.SONAR_ORG }} \
            -Dsonar.projectKey=${{ secrets.SONAR_PROJECT_KEY }} \
            -Dsonar.sources=src/ \
            -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/

  BUILD_AND_PUSH_TO_ECR:
    needs: SourceCode_Testing
    runs-on: ubuntu-latest
    steps:
      - name: Clone source code from the repo
        uses: actions/checkout@v4.2.2

      - name: Search and replace local variables with secrets
        run: |
          sed -i 's/^jdbc.username=.*/jdbc.username=${{ secrets.RDS_USER }}/' src/main/resources/application.properties
          sed -i 's/^jdbc.password=.*/jdbc.password=${{ secrets.RDS_PASSWORD }}/' src/main/resources/application.properties
          sed -i 's/db01/${{ secrets.RDS_ENDPOINT }}/' src/main/resources/application.properties

      - name: Build docker image and upload it to ECR
        uses: kciter/aws-ecr-action@v5
        with:
          access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          account_id: ${{ secrets.AWS_ACCOUNT_ID }}
          tags: latest,${{ github.sha }}
          repo: ecr-actions
          region: ${{ env.REGION }}
          dockerfile: ./Dockerfile
          path: "."

  DEPLOY_TO_ECS:
    needs: BUILD_AND_PUSH_TO_ECR
    runs-on: ubuntu-latest
    steps:
      - name: Set up AWS credentials
        uses: aws-actions/configure-aws-credentials@v4.0.2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.REGION }}

      - name: Deploy to ECS
        env:
          ECS_CLUSTER: ${{ secrets.ECS_CLUSTER }}
          ECS_SERVICE: ${{ secrets.ECS_SERVICE }}
        run: |
          aws ecs update-service --region ${{ env.REGION }} --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment

## AWS Infrastructure Setup

The AWS infrastructure is provisioned using Terraform and includes the following resources:

1. **ECR Repository**: For storing Docker images.
2. **ECS Cluster and Service**: For running the application in a containerized environment.
3. **RDS Instance**: For hosting the MySQL database.
4. **EC2 Instance**: For accessing the RDS instance.
5. **IAM Roles and Policies**: For managing permissions.
6. **Security Groups**: For controlling network traffic.

---

## Terraform Configuration

The Terraform configuration files define the AWS infrastructure. Key files include:

### 1. **ECR Configuration (`ecr.tf`)**
```hcl
resource "aws_ecr_repository" "foo" {
  name                 = "ecr-actions"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


### 2. **ECS Configuration ('ecs.tf')**
```hcl
resource "aws_ecs_cluster" "my_cluster" {
  name = "mvc-cluster"
}

resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "my-fargate-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "my-fargate-container",
      image     = "${aws_ecr_repository.foo.repository_url}:latest"
      essential = true,
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080,
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "fargate_service" {
  name            = "fargate-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.fargate_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0da724c295f8b5914"]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}


### 3. **RDS Configuration (`rds.tf`)**
```hcl
resource "aws_db_instance" "db" {
  allocated_storage      = 10
  db_name                = "accounts"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  identifier             = "db-instance"
  password               = random_password.rds_password.result
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.dbsg.id]
}

### Dockerfile
The Dockerfile is used to build the Spring MVC application and deploy it to a Tomcat server. It is a multi-stage Dockerfile to optimize the build process.

Dockerfile Code
```dockerfile
FROM openjdk:11 AS BUILD_IMAGE
RUN apt update && apt install maven -y
COPY ./ vprofile-project
RUN cd vprofile-project && mvn install

FROM tomcat:9-jre11
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=BUILD_IMAGE vprofile-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]

