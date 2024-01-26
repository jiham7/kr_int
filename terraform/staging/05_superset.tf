
data "aws_availability_zones" "available" {}

locals {
  region = "us-east-2"
  name   = "superset-k"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  container_name = "superset-c"
  container_port = 8088

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://superset.apache.org"
  }
}

################################################################################
# ECR
################################################################################

resource "aws_ecr_repository" "superset_repository" {
  name                 = "superset-repository"
  image_tag_mutability = "MUTABLE"
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

################################################################################
# ALB
################################################################################

resource "aws_lb" "superset_alb" {
  name               = "superset-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.superset_lb_sg.id]
  subnets            = module.vpc.public_subnets

  tags = local.tags
}

resource "aws_lb_listener" "superset_listener" {
  load_balancer_arn = aws_lb.superset_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.superset_tg.arn
  }
}

resource "aws_lb_target_group" "superset_tg" {
  name     = "superset-tg"
  port     = 8088
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 30
    interval            = 40
    path                = "/health"  
    protocol            = "HTTP"
    matcher             = "200-299"
  }
}
################################################################################
# ECS Cluster
################################################################################

resource "aws_ecs_cluster" "superset_cluster" {
  name = "${local.name}-cluster"
}

################################################################################
# IAM Roles for ECS Task
################################################################################

resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
    }],
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
    }],
  })

  tags = local.tags
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "ecs-task-policy"
  description = "Policy to allow ECS tasks to access Athena and S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "athena:*",
          "glue:*",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = "*"
      }
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}
################################################################################
# ECS Task Definition
################################################################################

resource "aws_ecs_task_definition" "superset_task" {
  family                   = local.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name  = local.container_name
    image = "${aws_ecr_repository.superset_repository.repository_url}:latest"  
    portMappings = [{
      containerPort = local.container_port
      hostPort      = local.container_port
    }]
    environment = [
      {
        name  = "SUPERSET_SECRET_KEY",
        value = "your_secret_key_here"  
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region        = "us-east-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/${local.name}"
}

resource "aws_iam_policy" "ecs_logging_policy" {
  name        = "ecs-logging-policy"
  description = "Allow ECS tasks to send logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      Effect   = "Allow",
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_logging_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_logging_policy.arn
}



################################################################################
# Security Group for ECS Tasks
################################################################################

resource "aws_security_group" "superset_sg" {
  name        = "${local.name}-sg"
  description = "Security group for Superset ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = local.container_port
    to_port     = local.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

################################################################################
# ECS Service
################################################################################

resource "aws_ecs_service" "superset_service" {
  name            = "${local.name}-service"
  cluster         = aws_ecs_cluster.superset_cluster.id
  task_definition = aws_ecs_task_definition.superset_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.superset_tg.arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.superset_sg.id]
  }

  tags = local.tags
}

resource "aws_security_group" "superset_lb_sg" {
  name        = "superset-lb-sg"
  description = "ALB security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
