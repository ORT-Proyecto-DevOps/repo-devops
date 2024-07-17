variable "prefix" {}
variable "environment" {}
variable "service_names" { type = list(string) }
variable "task_names" { type = list(string) }
variable "api_paths" { type = list(string) }