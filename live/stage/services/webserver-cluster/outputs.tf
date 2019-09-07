output "alb_dns_name" {
	#ime modula je navedeno u main.tf
	value = module.webserver_cluster.alb_dns_name
	description = "load balancer domain name"
}