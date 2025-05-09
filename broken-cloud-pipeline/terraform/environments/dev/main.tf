module "app_vpc" {
  source = "../../modules/vpc"
  name   = "app"
  cidr   = "10.40.0.0/16"
  tags   = var.tags
}
module "jenkins_vpc" {
  source = "../../modules/vpc"
  name   = "jenkins"
  cidr   = "10.41.0.0/16"
  tags   = var.tags
}
resource "aws_vpc_peering_connection" "app_to_jenkins" {
  vpc_id      = module.app_vpc.vpc_id
  peer_vpc_id = module.jenkins_vpc.vpc_id
  auto_accept = true
  tags        = var.tags
}
module "app_ecs" {
  source                = "../../modules/ecs_cluster"
  name                  = "app"
  vpc_id                = module.app_vpc.vpc_id
  private_subnets       = module.app_vpc.private_subnets
  container_name        = "hello-world"
  container_image       = "${var.ecr_registry}/${var.ecr_repo}:${var.image_tag}"
  container_count       = 2
  cpu                   = 128 #can utilize var.app_cpu as per challenge 512
  target_group_arn      = module.app_alb.target_group_arn
  alb_security_group_id = module.app_alb.alb_security_group_id
  tags                  = var.tags
  depends_on            = [module.app_alb] # Ensure ALB is fully configured
}
module "jenkins_ecs" {
  source                = "../../modules/ecs_cluster"
  name                  = "jenkins"
  vpc_id                = module.jenkins_vpc.vpc_id
  private_subnets       = module.jenkins_vpc.private_subnets
  container_name        = "jenkins"
  container_image       = "216989105561.dkr.ecr.eu-central-1.amazonaws.com/custom-jenkins:latest"
  container_count       = 1
  cpu                   = 256 #can utilize var.app_cpu as per challenge 512
  #target_group_arn      = aws_lb_target_group.jenkins_tg.arn
  target_group_arn      = module.jenkins_alb.target_group_arn
  alb_security_group_id = module.jenkins_alb.alb_security_group_id
  tags                  = var.tags
  depends_on            = [module.jenkins_alb] # Ensure ALB is fully configured
}
module "s3_logging" {
  source = "../../modules/s3_logging"
  name   = "pipeline"
  tags   = var.tags
}
module "app_alb" {
  source               = "../../modules/alb"
  name                 = "app"
  vpc_id               = module.app_vpc.vpc_id
  public_subnets       = module.app_vpc.public_subnets
  allowed_cidr         = ["0.0.0.0/0"]
  log_bucket_id        = module.s3_logging.bucket_id
  log_bucket_policy_id = module.s3_logging.bucket_policy_id # Pass policy ID
  tags                 = var.tags
  certificate_arn      = "arn:aws:acm:eu-central-1:216989105561:certificate/15556a87-717c-44e7-8d68-aaf146333c17"
}
module "jenkins_alb" {
  source               = "../../modules/alb"
  name                 = "jenkins"
  vpc_id               = module.jenkins_vpc.vpc_id
  public_subnets       = module.jenkins_vpc.public_subnets
  allowed_cidr         = ["0.0.0.0/0"] #allowed from all but can be adjusted with portugal CIDR 185.94.0.0/16 recomendation is WAF/CDN cloudfront in that case.not configured due to submision issue
  log_bucket_id        = module.s3_logging.bucket_id
  log_bucket_policy_id = module.s3_logging.bucket_policy_id
  tags                 = var.tags
  certificate_arn      = "arn:aws:acm:eu-central-1:216989105561:certificate/15556a87-717c-44e7-8d68-aaf146333c17"
}
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/lambda.zip" # Output sending to dev/lambda/
}
resource "aws_lambda_function" "ecs_log_exporter" {
  function_name    = "ecs-log-exporter"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.lambda.output_path         # Use generated zip
  source_code_hash = data.archive_file.lambda.output_base64sha256 # Correct hash
  environment {
    variables = {
      BUCKET_NAME = module.s3_logging.bucket_id
    }
  }
  tags       = var.tags
  depends_on = [data.archive_file.lambda] # Ensure zip is created first
}
resource "aws_iam_role" "lambda" {
  name = "lambda-ecs-log-exporter-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}
resource "aws_iam_role_policy" "lambda" {
  name = "lambda-ecs-log-exporter-policy"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "*" },
      { Effect = "Allow", Action = ["logs:CreateExportTask", "logs:DescribeExportTasks"], Resource = "*" },
      { Effect = "Allow", Action = "s3:PutObject", Resource = "${module.s3_logging.bucket_arn}/ecs/*" }
    ]
  })
}
resource "aws_cloudwatch_event_rule" "ecs_log_export_schedule" {
  name                = "ecs-log-export-schedule"
  schedule_expression = "rate(1 hour)"
  tags                = var.tags
}
resource "aws_cloudwatch_event_target" "ecs_log_export_lambda" {
  rule      = aws_cloudwatch_event_rule.ecs_log_export_schedule.name
  target_id = "ecsLogExporter"
  arn       = aws_lambda_function.ecs_log_exporter.arn
}
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_log_exporter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_log_export_schedule.arn
}
resource "aws_sns_topic" "pipeline_notifications" {
  name = "pipeline-notifications"
  tags = var.tags
}
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = "bilalamjad0351@gamail.com"
}
