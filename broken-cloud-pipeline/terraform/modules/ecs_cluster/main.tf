# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"
  tags = var.tags
}

# Security Group for ECS Instances
resource "aws_security_group" "ecs_instance_sg" {
  name_prefix = "${var.name}-ecs-sg-"
  vpc_id      = var.vpc_id
   ingress {
    from_port       = 8080  # Add explicit container port
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }
  ingress {
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to pull images
  }
  tags = var.tags
}

# IAM Role for ECS Instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.name}-ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# Launch Template for EC2 Instances
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "ecs" {
  name_prefix            = "${var.name}-ecs-"
  image_id               = data.aws_ssm_parameter.ecs_ami.value
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ecs_instance_sg.id]
  iam_instance_profile { arn = aws_iam_instance_profile.ecs_instance_profile.arn }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
  EOF
  )
  tags = var.tags
}

# Autoscaling Group
resource "aws_autoscaling_group" "ecs" {
  name_prefix         = "${var.name}-ecs-asg-"
  vpc_zone_identifier = var.private_subnets # Place in private subnets
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.name}-ecs-cluster"
    propagate_at_launch = true
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

# Capacity Provider
resource "aws_ecs_capacity_provider" "this" {
  name = "${var.name}-ecs-cp"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn
    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    base              = 1
    weight            = 100
  }
}

# Task Definition with Flaw
resource "aws_ecs_task_definition" "this" {
  family       = "${var.name}-task"
  network_mode = "bridge"
  container_definitions = jsonencode([{
    name   = var.container_name
    image  = var.container_image
    cpu    = var.cpu
    memory = 512
    portMappings = [{
      containerPort = var.name == "jenkins" ? 8080 : 8080 # Changed to 8080 for both jenkins and hello-world
      hostPort      = 0
      protocol      = "tcp"
    }]
    environment = [
      { name = "FORCE_UPDATE", value = timestamp() }  # Forces a new revision on each apply
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.name}-task"
        "awslogs-region"        = "eu-central-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  // FLAW: CPU over-allocated (256 units for hello-world is excessive)
}

# Update ECS Service to use ALB
resource "aws_ecs_service" "this" {
  name                              = "${var.name}-service"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.container_count
  health_check_grace_period_seconds = 300 # Give 300s for container to start
  load_balancer {
    target_group_arn = var.target_group_arn # Passed from ALB module
    container_name   = var.container_name
    container_port = var.name == "jenkins" ? 8080 : 8080
  }
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight            = 1
  }

  depends_on = [var.target_group_arn, aws_ecs_cluster_capacity_providers.this] 
}
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}-task"
  retention_in_days = 7
}
