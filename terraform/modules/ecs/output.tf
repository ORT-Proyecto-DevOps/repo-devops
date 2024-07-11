output "vpc_id" {
  value = aws_vpc.ecs_vpc.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.ecs_igw.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_subnet_2.id
}

output "route_table_id" {
  value = aws_route_table.ecs_public_rt.id
}

output "public_subnet_1_association_id" {
  value = aws_route_table_association.public_subnet_1_association.id
}

output "public_subnet_2_association_id" {
  value = aws_route_table_association.public_subnet_2_association.id
}

output "security_group_id" {
  value = aws_security_group.ecs_sg.id
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.ecs_log_group.name
}

output "ecs_cluster_ids" {
  value = [for cluster in aws_ecs_cluster.ecs_cluster : cluster.id]
}

output "ecs_task_definition_arns" {
  value = [for task in aws_ecs_task_definition.ecs_task : task.arn]
}

output "ecs_service_names" {
  value = [for service in aws_ecs_service.ecs_service : service.name]
}