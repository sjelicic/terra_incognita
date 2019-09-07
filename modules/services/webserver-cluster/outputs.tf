/*output "alb_dns_name" {
  value       = aws_lb.example_load_balancer.dns_name
  description = "domain name of the application load balancer"
}*/

#autoscaling group ime za prod/serviuces/webserver-cluster/main.tf
#ime je potrebno za ASG schedule
output "asg_name" {
  value = aws_autoscaling_group.example_ASG.name
  description = "ASG name"
}

output "alb_dns_name" {
  value = aws_lb.example_load_balancer.dns_name
  description = "load balancer domain name"
}

output "alb_security_group_id" {
  value = aws_security_group.load-balancer-security-group.id
  description = "security group ID attached to the load balancer"
}