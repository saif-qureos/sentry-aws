resource "aws_rds_cluster_instance" "this" {
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
 depends_on = [
   aws_rds_cluster.this
 ]
}


resource "aws_rds_cluster" "this" {
  cluster_identifier_prefix       = "${var.id}-"
  final_snapshot_identifier       = "${var.id}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  copy_tags_to_snapshot           = true
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = "13.6"
  database_name                   = var.db_name
  master_username                 = var.db_user
  master_password                 = var.db_password
  backup_retention_period         = 5 # days
  snapshot_identifier             = var.snapshot_identifier
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_subnet_group_name            = aws_db_subnet_group.this.id
  deletion_protection             = var.protection
  allow_major_version_upgrade     = true
  enable_http_endpoint            = true
  tags                            = var.tags

  serverlessv2_scaling_configuration {
    min_capacity = 1
    max_capacity = var.max_capacity
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [snapshot_identifier, final_snapshot_identifier]
  }

}

resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.id}-"
  subnet_ids  = var.private_subnet_ids
  tags        = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.id}-rds-"
  vpc_id      = var.vpc_id
  tags        = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_ingress_ec2" {
  description              = "EC2"
  type                     = "ingress"
  from_port                = aws_rds_cluster.this.port
  to_port                  = aws_rds_cluster.this.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.sg_sentry_9000.id
}


resource "aws_security_group" "sg_sentry_9000" {
  name   = "sg_sentry_9000"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}



# resource "aws_alb_target_group_attachment" "sentryserver_phys_exter" {
#   target_group_arn = aws_alb_target_group.tg_sentry.arn
#   target_id        = aws_instance.sentryserver.id  
#   port             = 9000
#   depends_on = [
#     aws_instance.sentryserver
#   ]
# }

resource "aws_alb_target_group" "tg_sentry" {  
  name     = "tg-sentry"  
  port     = "9000"  
  protocol = "HTTP"  
  vpc_id   = var.vpc_id   

  health_check {    
    healthy_threshold   = 10    
    unhealthy_threshold = 10
    interval            = 10    
    path                = var.healthcheck_path   
    port                = "9000"  
  }
}


data "template_file" "post_launch" {
  template = "${file("${path.module}/templates/post_launch.tpl")}"

  vars = {
    db_name = "${var.db_name}"
    db_user = "${var.db_user}"
    db_password = "${var.db_password}"
    port = "${aws_rds_cluster.this.port}"
    endpoint = "${aws_rds_cluster.this.endpoint}"
  }
}

# resource "aws_instance" "sentryserver" {
#   ami                         = var.ami_id
#   instance_type               = var.instance_type
#   subnet_id                   = var.is_private ?  var.private_subnet_ids[0] : var.public_subnet_ids[0]
#   vpc_security_group_ids      = [aws_security_group.sg_sentry_9000.id]
#   associate_public_ip_address = var.is_private ? false : true
#   key_name = var.key_name
#   tags = {
#     Name = "Sentry-Server"
#   }

#   provisioner "file" {
#     content      = data.template_file.post_launch.rendered
#     destination = "/tmp/startup.sh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#         "sudo sed -i -e 's/\r$//' /tmp/startup.sh",
#         "sudo chmod +x /tmp/startup.sh",
#         "sudo /tmp/startup.sh",
#         "cd /home/theuser/self-hosted-21.3.0/ && sudo docker-compose up -d"
#     ]
#   }
#   connection {
#     type        = "ssh"
#     user        = "theuser"
#     private_key = file(var.keypath)
#     host        = var.is_private ? self.private_ip : self.public_ip
#   }

#   depends_on = [
#     aws_rds_cluster_instance.this
#   ]
# }

resource "aws_alb" "alb_sentry" {  
  name            = "lb-sentry"
  internal        = var.is_private  
  subnets         = var.is_private ? var.private_subnet_ids : var.public_subnet_ids
  security_groups = [aws_security_group.sg_sentry_9000.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.alb_sentry.arn
  depends_on        = [aws_alb.alb_sentry] # https://github.com/terraform-providers/terraform-provider-aws/issues/9976
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_alb_listener" "ssl_sentry_443" {
  load_balancer_arn = aws_alb.alb_sentry.arn
  port              = "443"
  protocol          = "HTTPS"
  depends_on        = [aws_alb_target_group.tg_sentry]
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
   
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Nothing Here!"
      status_code  = "400"
    }
  }
}

resource "aws_lb_listener_rule" "host_based_weighted_routing" {
  listener_arn = aws_alb_listener.ssl_sentry_443.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tg_sentry.arn
  }

  condition {
    host_header {
      values = [var.domain]
    }
  }
}

resource "aws_launch_configuration" "sentry_launch_config" {
  name_prefix          = "sentry-${var.environment_tag}-${var.region}-"
  image_id             = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  user_data = data.template_file.post_launch.rendered
  security_groups             = [aws_security_group.sg_sentry_9000.id]
  associate_public_ip_address = var.is_private ? false : true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "sentry_asg" {
  name                 = aws_launch_configuration.sentry_launch_config.name
  launch_configuration = aws_launch_configuration.sentry_launch_config.name
  min_size             = var.asg_min_size
  desired_capacity     = var.asg_desired_capacity
  max_size             = var.asg_max_size
  vpc_zone_identifier  = var.is_private ? var.private_subnet_ids : var.public_subnet_ids
  health_check_type    = "EC2"
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance"]
  target_group_arns    = "${aws_alb_target_group.tg_sentry.arn}"

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = aws_launch_configuration.sentry_launch_config.name
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "sentry"
      propagate_at_launch = true
    },
    {
      key                 = "env"
      value               = var.environment_tag
      propagate_at_launch = true
    },
    {
      key                 = "tf-managed"
      value               = "True"
      propagate_at_launch = true
    },
  ]
}

resource "aws_route53_record" "this" {
  name    = var.domain
  type    = "A"
  zone_id = var.zone_id

  alias {
    name                   = aws_alb.alb_sentry.dns_name
    zone_id                = aws_alb.alb_sentry.zone_id
    evaluate_target_health = false
  }
}
