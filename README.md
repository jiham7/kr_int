# Superset on AWS with Athena Integration

This README provides an overview of the infrastructure and resources deployed using Terraform to host Apache Superset and allow it to query data from an S3 bucket using Amazon Athena. 

## Overview

The Terraform configuration in this repository deploys the following components:

1. **S3 Bucket**: An Amazon S3 bucket (`jiham-k-test`) is created to store data that Superset will query through Athena.

2. **Athena Database and Table**: An Athena database (`lottery_database`) and an external table (`lottery_table`) are created to enable querying the data stored in the S3 bucket. The data schema for the table includes columns for draw date, winning numbers, mega ball, and multiplier.

3. **AWS Identity and Access Management (IAM) Roles and Policies**: IAM roles and policies are defined to grant permissions to Superset and ECS tasks to access Athena and the S3 bucket securely.

4. **Amazon Elastic Container Service (ECS)**: An ECS cluster and task definition are defined for hosting Apache Superset. This allows Superset to run as a containerized application with the necessary IAM permissions.

5. **Amazon Elastic Container Registry (ECR)**: An ECR repository is created to store the Docker image for Superset.

6. **Amazon Elastic Load Balancer (ALB)**: An Application Load Balancer is used to route traffic to Superset hosted on ECS.

## ToDo

1. **Store Secrets Securely**: Instead of storing sensitive information like secret keys and credentials directly in the Terraform configuration, use AWS Secrets Manager to store and manage secrets securely. Retrieve secrets dynamically from Secrets Manager during runtime.

2. **Logging and Monitoring**: Implement comprehensive logging and monitoring solutions using Amazon CloudWatch and AWS CloudTrail to monitor and track activities and detect any security issues.

3. **High Availability**: Consider deploying Superset in a multi-Availability Zone (AZ) setup for high availability and fault tolerance.

4. **Scaling**: Plan for scaling based on expected load. Implement auto-scaling for ECS tasks and consider using Amazon RDS for a production database backend.


## Getting Started

To deploy this infrastructure, follow these steps:

1. Clone this repository to your local machine.

2. Install Terraform (if not already installed).

3. Configure AWS CLI with your AWS credentials.

4. Navigate to the root directory of the cloned repository.

5. Run the following commands to initialize Terraform in terraform/staging and create the infrastructure:

   terraform init


   terraform apply

## Live Superset
This is the live superset DNS: 
http://superset-alb-315046454.us-east-2.elb.amazonaws.com/

username: admin


password: admin

## Terraform Plan
I have added the terraform plan -destroy as terraform-destroy-plan.txt to show all resources deployed

## SQL queries
I have added the sql queries in the SQL-queries.txt