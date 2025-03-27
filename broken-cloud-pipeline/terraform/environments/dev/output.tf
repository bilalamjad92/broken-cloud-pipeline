output "app_alb_dns" {
  value = module.app_alb.alb_dns_name
}

output "jenkins_alb_dns" {
  value = module.jenkins_alb.alb_dns_name
}

output "target_group_arn" {
  value = module.app_alb.target_group_arn
}

output "alb_security_group_id" {
  value = module.app_alb.alb_security_group_id
}

