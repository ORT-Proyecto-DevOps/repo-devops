#!/bin/bash

# Desactivar la paginación de AWS CLI
export AWS_PAGER=""

# Obtener la lista de todas las definiciones de tareas
task_definitions=$(aws ecs list-task-definitions --query 'taskDefinitionArns[*]' --output text)

# Recorrer y borrar cada definición de tarea
for task_definition in $task_definitions; do
    aws ecs deregister-task-definition --task-definition $task_definition
done
