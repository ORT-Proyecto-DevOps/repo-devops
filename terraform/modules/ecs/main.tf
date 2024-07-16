resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "10.0.0.0/16"
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

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-be-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-be-public-subnet-2"
  }
}

resource "aws_nat_gateway" "ecs_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "ecs-nat-gateway"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "ecs-be-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "ecs-be-private-subnet-2"
  }
}

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

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
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
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
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
  description = "Security group for public ALB"
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

resource "aws_lb" "public_lb" {
  name               = "${var.prefix}-public-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
  }
}


resource "aws_lb_listener" "public_listener" {
  load_balancer_arn = aws_lb.public_lb.arn
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
  name        = "${var.prefix}-tg-${var.service_names[count.index]}-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id

  health_check {
    path                = "/shipping/c"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
}

resource "aws_lb_listener_rule" "service_rules" {
  count        = length(var.service_names)
  listener_arn = aws_lb_listener.public_listener.arn
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
      essential = true
      portMappings = [
        {
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
  name            = "${var.prefix}-${var.service_names[count.index]}-${var.environment}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task[count.index].arn
  launch_type     = "FARGATE"
  desired_count   = 1
  deployment_maximum_percent = 200

  network_configuration {
    subnets          = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
    container_name   = var.service_names[count.index]
    container_port   = 8080
  }
}