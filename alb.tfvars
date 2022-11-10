namespace = "cl"

stage = "prod"

name = "alb"

vpc_cidr_block = "172.16.0.0/16"

internal = false

http_enabled = true

http_redirect = false

access_logs_enabled = true

alb_access_logs_s3_bucket_force_destroy = true

alb_access_logs_s3_bucket_force_destroy_enabled = true

cross_zone_load_balancing_enabled = false

http2_enabled = true

idle_timeout = 60

ip_address_type = "ipv4"

deletion_protection_enabled = false

deregistration_delay = 15

health_check_path = "/"

health_check_timeout = 10

health_check_healthy_threshold = 2

health_check_unhealthy_threshold = 2

health_check_interval = 15

health_check_matcher = "200-399"

target_group_port = 80

target_group_target_type = "ip"

stickiness = {
  cookie_duration = 60
  enabled         = true
}



##### ECS
container_memory             = 256
container_memory_reservation = 128
container_cpu                = 256
essential                    = true
readonly_root_filesystem     = false


container_port_mappings = [
  {
    containerPort = 8080
    hostPort      = 80
    protocol      = "tcp"
  },
  {
    containerPort = 8081
    hostPort      = 443
    protocol      = "udp"
  }
]

log_configuration = {
  logDriver = "json-file"
  options = {
    "max-size" = "10m"
    "max-file" = "3"
  }
  secretOptions = null
}

privileged = false

extra_hosts = [{
  ipAddress = "127.0.0.1"
  hostname  = "app.local"
  },
]

hostname        = "hostname"
pseudo_terminal = true
interactive     = true

# ECR encryption
encryption_configuration = {
  encryption_type = "AES256"
  kms_key         = null
}

# ECS
ecs_launch_type = "FARGATE"

network_mode = "awsvpc"

ignore_changes_task_definition = true

assign_public_ip = false

propagate_tags = "TASK_DEFINITION"

deployment_minimum_healthy_percent = 100

deployment_maximum_percent = 200

deployment_controller_type = "ECS"

desired_count = 1

task_memory = 512

task_cpu = 256

container_name = "phoenix"

container_image = "phoenix"

container_essential = true

container_readonly_root_filesystem = false

container_environment = [
  {
    name  = "string_var"
    value = "I am a string"
  },
  {
    name  = "true_boolean_var"
    value = true
  },
  {
    name  = "false_boolean_var"
    value = false
  },
  {
    name  = "integer_var"
    value = 42
  }
]
