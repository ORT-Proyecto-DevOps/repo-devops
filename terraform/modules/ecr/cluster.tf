resource "aws_ecs_cluster" "ecs_cluster" {
  name = "aws-ecs-be-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ecs-be-vpc"
  }
}

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "ecs-be-igw"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-be-public-subnet-1"
  }
}


resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-be-public-subnet-2"
  }
}

resource "aws_route_table" "ecs_public_rt" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name = "ecs-be-public-rt"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.ecs_public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.ecs_public_rt.id
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ecs-be-sg"
  }
}
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/aws-ecs-be-services"
  retention_in_days = 1  # Ajusta la retención según tus necesidades

  lifecycle {
    ignore_changes = [
      retention_in_days
    ]
    prevent_destroy = false  # Habilita la eliminación durante `terraform destroy`
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "LabRole"
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "aws_ecs_be_tasks"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  task_role_arn           = "${data.aws_iam_role.ecs_task_execution_role.arn}"
  execution_role_arn      = "${data.aws_iam_role.ecs_task_execution_role.arn}"

  container_definitions = jsonencode([
    {
      name  = "be-service-1"
      image = "placeholder"  # Hacer imagen dummy para las tasks, cada task va a tener que tener 3 imagenes por servicio (dev, prod, test) usar count.
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
          "awslogs-group"         = "/ecs/aws-ecs-be-services"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "aws-ecs-be-services"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}
