resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecs-microservices-vpc"
  }
}


resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "ecs-be-igw"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.1.0/24"
   availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-be-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-be-private-subnet-2"
  }
}

resource "aws_route_table" "ecs_private_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name = "ecs-be-public-rt"
  }
}

resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.ecs_private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.ecs_private_rt.id
}

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

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/aws-ecs-logs-${var.environment}"
  retention_in_days = 1

  lifecycle {
    ignore_changes = [
      retention_in_days
    ]
    prevent_destroy = false  # Habilita la eliminación durante `terraform destroy`
  }
}

resource "aws_lb" "internal_lb" {
  count              = 4
  name               = "${var.prefix}-internal-lb-${count.index}-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

resource "aws_lb_listener" "internal_listener" {
  count             = 4
  load_balancer_arn = aws_lb.internal_lb[count.index].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
  }
}

# Target Groups
resource "aws_lb_target_group" "ecs_tg" {
  count       = 4
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

data "aws_iam_role" "ecs_task_execution_role" {
  name = "LabRole"
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.prefix}-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

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
      environment = [
        {
          name  = "SERVICE_1_URL"
          value = "http://${aws_lb.internal_lb[0].dns_name}"
        },
        {
          name  = "SERVICE_2_URL"
          value = "http://${aws_lb.internal_lb[1].dns_name}"
        },
        {
          name  = "SERVICE_3_URL"
          value = "http://${aws_lb.internal_lb[2].dns_name}"
        }
      ]
    }
  }])
}

resource "aws_ecs_service" "ecs_service" {
  count           = length(var.service_names)
  name            = "${var.prefix}-${var.service_names[count.index]}-${var.environment}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task[count.index].arn
  launch_type     = "FARGATE"
  desired_count   = 2

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
  count       = 4
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = var.service_names[count.index]
}

resource "aws_api_gateway_method" "service" {
  count         = 4
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.service[count.index].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "service" {
  count                   = 4
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.service[count.index].id
  http_method             = aws_api_gateway_method.service[count.index].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.internal_lb[count.index].dns_name}/{proxy}"
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.environment

  depends_on = [aws_api_gateway_integration.service]
}