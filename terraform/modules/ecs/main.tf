# VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecs-microservices-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "ecs-be-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# Public Subnet for NAT Gateway
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-be-public-subnet-1"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "ecs_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "ecs-nat-gateway"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "ecs-be-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "ecs-be-private-subnet-2"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name = "ecs-be-public-rt"
  }
}

# Route Table for Private Subnets with NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecs_nat_gateway.id
  }

  tags = {
    Name = "ecs-be-private-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ecs_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for internal ALBs"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ecs_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/aws-ecs-logs-${var.environment}"
  retention_in_days = 1

  lifecycle {
    ignore_changes = [
      retention_in_days
    ]
    prevent_destroy = false
  }
}

# Internal Load Balancer
resource "aws_lb" "internal_lb" {
  name               = "${var.prefix}-internal-lb-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

# Listeners for Load Balancers
resource "aws_lb_listener" "internal_listener" {
  load_balancer_arn = aws_lb.internal_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No se encontraron rutas coincidentes"
      status_code  = "404"
    }
  }
}

# Target Groups
resource "aws_lb_target_group" "ecs_tg" {
  count       = length(var.service_names)
  name        = "${var.prefix}-tg-${var.service_names[count.index]}-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
}

# Listener Rules for Load Balancers
resource "aws_lb_listener_rule" "service_rules" {
  count        = length(var.service_names)
  listener_arn = aws_lb_listener.internal_listener.arn
  priority     = 100 + count.index

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
  }

  condition {
    path_pattern {
      values = ["/${var.service_names[count.index]}/*"]
    }
  }
}

# IAM Role for ECS Task Execution
data "aws_iam_role" "ecs_task_execution_role" {
  name = "LabRole"
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecsTaskExecutionPolicy"
  role = data.aws_iam_role.ecs_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:log-group:/ecs/*"
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.prefix}-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "ecs_task" {
  count                    = length(var.task_names)
  family                   = "${var.prefix}-${var.task_names[count.index]}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  task_role_arn      = data.aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = var.service_names[count.index]
      image = "hello-world:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/aws-ecs-logs-${var.environment}"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [
        {
          name  = "shipping-service"
          value = "http://${aws_lb.internal_lb.dns_name}/${var.service_names[0]}"
        },
        {
          name  = "payments-service"
          value = "http://${aws_lb.internal_lb.dns_name}/${var.service_names[1]}"
        },
        {
          name  = "products-service"
          value = "http://${aws_lb.internal_lb.dns_name}/${var.service_names[2]}"
        }
      ]
    }
  ])
}

# ECS Services
resource "aws_ecs_service" "ecs_service" {
  count           = length(var.service_names)
  name            = "${var.prefix}-${var.service_names[count.index]}-${var.environment}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task[count.index].arn
  launch_type     = "FARGATE"
  desired_count   = 2
  deployment_maximum_percent = 200

  network_configuration {
    subnets          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
    container_name   = var.service_names[count.index]
    container_port   = 80
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name = "${var.prefix}-api-gateway-${var.environment}"
}

resource "aws_api_gateway_resource" "service" {
  count       = length(var.service_names)
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = var.service_names[count.index]
}

resource "aws_api_gateway_method" "service" {
  count         = length(var.service_names)
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.service[count.index].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "service" {
  count                   = length(var.service_names)
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.service[count.index].id
  http_method             = aws_api_gateway_method.service[count.index].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.internal_lb.dns_name}/${var.service_names[count.index]}"
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.environment

  depends_on = [aws_api_gateway_integration.service]
}
