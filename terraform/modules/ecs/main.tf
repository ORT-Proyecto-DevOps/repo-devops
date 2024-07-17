resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-2"
  }
}

resource "aws_nat_gateway" "ecs_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.prefix}-nat-gateway"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix}-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix}-private-subnet-2"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecs_nat_gateway.id
  }

  tags = {
    Name = "${var.prefix}-private-rt"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
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

resource "aws_security_group" "ecs_sg" {
  name        = "${var.prefix}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.prefix}-alb-sg"
  description = "Security group for ALBs"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    prevent_destroy = false
  }
}

resource "aws_lb" "internal_lb" {
  name               = "${var.prefix}-internal-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_lb_listener" "internal_listener" {
  load_balancer_arn = aws_lb.internal_lb.arn
  port              = "8080"
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

resource "aws_lb_target_group" "ecs_tg" {
  count       = length(var.service_names)
  name        = "${var.prefix}-tg-${element(var.service_names, count.index)}-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id

  # Omite health_check para deshabilitarlo
}

resource "aws_lb_listener_rule" "service_rules" {
  count        = length(var.service_names)
  listener_arn = aws_lb_listener.internal_listener.arn
  priority     = 100 + count.index

  action {
    type             = "forward"
    target_group_arn = element(aws_lb_target_group.ecs_tg[*].arn, count.index)
  }

  condition {
    path_pattern {
      values = ["/${element(var.api_paths, count.index)}/*"]
    }
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
  family                   = "${var.prefix}-${element(var.task_names, count.index)}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  task_role_arn      = data.aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = data.aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = element(var.service_names, count.index)
      image = "hello-world:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          containerPort = 8080
          hostPort      = 8080
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
          value = "http://${aws_lb.public_lb.dns_name}/${var.service_names[0]}"
        },
        {
          name  = "payments-service"
          value = "http://${aws_lb.public_lb.dns_name}/${var.service_names[1]}"
        },
        {
          name  = "products-service"
          value = "http://${aws_lb.public_lb.dns_name}/${var.service_names[2]}"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
  count           = length(var.service_names)
  name            = "${var.prefix}-${element(var.service_names, count.index)}-${var.environment}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = element(aws_ecs_task_definition.ecs_task[*].arn, count.index)
  launch_type     = "FARGATE"
  desired_count   = 1
  deployment_maximum_percent = 200

  network_configuration {
    subnets          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = element(aws_lb_target_group.ecs_tg[*].arn, count.index)
    container_name   = element(var.service_names, count.index)
    container_port   = 8080
  }
}

resource "aws_api_gateway_rest_api" "main" {
  name = "${var.prefix}-api-gateway-${var.environment}"
}

resource "aws_api_gateway_resource" "service" {
  count       = length(var.api_paths)
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = element(var.api_paths, count.index)
}

resource "aws_api_gateway_method" "service" {
  count         = length(var.api_paths)
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = element(aws_api_gateway_resource.service[*].id, count.index)
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "service" {
  count                   = length(var.api_paths)
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = element(aws_api_gateway_resource.service[*].id, count.index)
  http_method             = aws_api_gateway_method.service[count.index].http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.internal_lb.dns_name}/${element(var.api_paths, count.index)}"
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.environment

  depends_on = [aws_api_gateway_integration.service]
}
