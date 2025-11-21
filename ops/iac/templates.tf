# Container definitions for ECS using modern Terraform approach

# Get current AWS region
data "aws_region" "current" {}

# Container definition for primary ECS service with RDS integration
locals {
  container_definition = jsonencode([
    {
      name      = var.container_name
      image     = "${module.ecr.repository_url}:latest"
      cpu       = tonumber(var.cpu)
      memory    = tonumber(var.memory)
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "NODE_ENV"
          value = var.environment == "staging" ? "staging" : "development"
        },
        {
          name  = "DB_HOST"
          value = module.rds.connection_info.host
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = "infrastructure"
        },
        {
          name  = "DB_USERNAME"
          value = "postgres"
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.id
        },
        {
          name  = "XRAY_TRACING_NAME"
          value = var.ecs_name
        },
        {
          name  = "REDIS_HOST"
          value = module.elasticache.connection_info.host
        },
        {
          name  = "REDIS_PORT"
          value = tostring(module.elasticache.connection_info.port)
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${module.rds.secrets_manager_secret_arn}:password::"
        },
        {
          name      = "REDIS_PASSWORD"
          valueFrom = "${module.elasticache.secrets_manager_secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.ecs_name}"
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  container_definition_standby = jsonencode([
    {
      name      = var.container_name
      image     = "${module.ecr.repository_url}:latest"
      cpu       = tonumber(var.cpu)
      memory    = tonumber(var.memory)
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "NODE_ENV"
          value = var.environment == "staging" ? "staging" : "development"
        },
        {
          name  = "DB_HOST"
          value = module.rds_standby.connection_info.host
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = "infrastructure"
        },
        {
          name  = "DB_USERNAME"
          value = "postgres"
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.id
        },
        {
          name  = "XRAY_TRACING_NAME"
          value = "${var.ecs_name}-standby"
        },
        {
          name  = "REDIS_HOST"
          value = module.elasticache.connection_info.host
        },
        {
          name  = "REDIS_PORT"
          value = tostring(module.elasticache.connection_info.port)
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${module.rds_standby.secrets_manager_secret_arn}:password::"
        },
        {
          name      = "REDIS_PASSWORD"
          valueFrom = "${module.elasticache.secrets_manager_secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.ecs_name}-standby"
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
