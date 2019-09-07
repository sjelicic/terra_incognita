#this will be provided (heh) by the user of the module
/*provider "aws" {
  region = "eu-central-1"
}*/

#remote backend
terraform {
  backend "s3" {
    bucket = "state-dump"
    #imamo 1:1 mapiranje izmadju folder layout-a i S3
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "state-dump-locks"
    encrypt        = true
  }
}


/*resource "aws_instance" "example_instance" {
  ami           = "ami-0ac05733838eabc06"
  instance_type = "t2.micro"
  #implicit dependency
  vpc_security_group_ids = [aws_security_group.example_sec_group.id]

  # https://stackoverflow.com/questions/2500436/how-does-cat-eof-work-in-bash
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello Wolrd" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  tags = {
    Name = "terraform-example"
  }
}*/

locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}


resource "aws_launch_configuration" "example_launch_configuration" {
  image_id        = "ami-0ac05733838eabc06"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.example_sec_group.id]

  /*  user_data = <<-EOF
              #!/bin/bash
              echo "Hello Wolrd" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF*/
  user_data = data.template_file.user_data.rendered
}

resource "aws_autoscaling_group" "example_ASG" {
  launch_configuration = aws_launch_configuration.example_launch_configuration.name

  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.example_lb_target_group.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_lb" "example_load_balancer" {
  name               = "${var.cluster_name}-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.load-balancer-security-group.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example_load_balancer.arn
  port              = local.http_port
  protocol          = "HTTP"

  #by default return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not find... pederu"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "example_lb_target_group" {
  #Error: "name" cannot be longer than 32 characters
  name = "${var.cluster_name}-alb-target"

  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "lb-listener-rules" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    field  = "path-pattern"
    values = ["*"]
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_lb_target_group.arn
  }

}


# moramo da stavimo do znanja AWS instanci da koristi ovu security grupu
/*resource "aws_security_group" "example_sec_group" {
  name = "${var.cluster_name}-security-group-example"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}*/

resource "aws_security_group" "example_sec_group" {
  name = "${var.cluster_name}-security-group-example"
}

resource "aws_security_group_rule" "allow_inbound_to_instances" {
  type = "ingress"
  security_group_id = aws_security_group.example_sec_group.id

  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = "tcp"
  cidr_blocks = local.all_ips
}


#defined ingress/egress rules by inline blocks
/*resource "aws_security_group" "load-balancer-security-group" {
  name = "${var.cluster_name}-alb-security-group-example"

  #Allow inbound HTTP requests
  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocl
    cidr_blocks = local.all_ips
  }

  #Allow all outbound requests
  egress {
    from_port = local.any_port
    to_port   = local.any_port
    #If you select a protocol of "-1" (semantically equivalent to "all", which is not a valid value here), you must specify a "from_port" and "to_port" equal to 0. If not icmp, tcp, udp, or "-1" use the protocol number
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }
}*/


/*output "instance_public_ip" {
  value       = aws_instance.example_instance.public_ip
  description = "publci ip of the web server"
}*/

resource "aws_security_group" "load-balancer-security-group" {
  name = "${var.cluster_name}-alb-security-group-example"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.load-balancer-security-group.id

    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "all_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.load-balancer-security-group.id

    from_port = local.any_port
    to_port   = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
}



data "aws_vpc" "default" {
  default = true

}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "terraform_remote_state" "db_example" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "eu-central-1"
/*    bucket = "state-dump"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "eu-central-1"
  }*/
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
  #template = file("user-data.sh")

  vars = {
    server_port = "${var.server_port}"
    db_address  = data.terraform_remote_state.db_example.outputs.address
    db_port     = data.terraform_remote_state.db_example.outputs.port
  }
}






