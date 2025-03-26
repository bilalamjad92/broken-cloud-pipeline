output "app_alb_dns" {
  value = module.app_alb.alb_dns_name
}

output "jenkins_alb_dns" {
  value = module.jenkins_alb.alb_dns_name
}