terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.26.0"
    }
  }
  required_version = "~> 0.14.5"
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet
}

resource "aws_subnet" "subnet_public2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet2
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "sg_sentry_9000" {
  name   = "sg_sentry_9000"
  vpc_id = aws_vpc.vpc.id

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

resource "aws_alb_target_group_attachment" "sentryserver_phys_exter" {
  target_group_arn = aws_alb_target_group.tg_sentry.arn
  target_id        = aws_instance.sentryserver.id  
  port             = 9000
}

resource "aws_alb_target_group" "tg_sentry" {  
  name     = "tg-sentry"  
  port     = "9000"  
  protocol = "HTTP"  
  vpc_id   = aws_vpc.vpc.id   

  health_check {    
    healthy_threshold   = 10    
    unhealthy_threshold = 10
    interval            = 10    
    path                = "/"    
    port                = "9000"  
  }
}

resource "aws_instance" "sentryserver" {
  ami                         = var.ami_id
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_sentry_9000.id]
  associate_public_ip_address = true

  tags = {
    Name = "Sentry-Server"
  }

  provisioner "file" {
    source      = "./startup.sh"
    destination = "/tmp/startup.sh"
  }

  provisioner "remote-exec" {
    inline = [
        "sudo chmod +x /tmp/startup.sh",
        "sudo /tmp/startup.sh",
    ]
  }
  connection {
    type        = "ssh"
    user        = "theuser"
    password    = ""
    private_key = file(var.keypath)
    host        = self.public_ip
  }
}

resource "aws_alb" "alb_sentry" {  
  name            = "lb-sentry"  
  subnets         = [aws_subnet.subnet_public.id,aws_subnet.subnet_public2.id]
  security_groups = [aws_security_group.sg_sentry_9000.id]
  internal        = false
}

resource "aws_alb_listener" "ssl_sentry_443" {
  load_balancer_arn = aws_alb.alb_sentry.arn
  port              = "443"
  protocol          = "HTTPS"
  depends_on        = [aws_alb_target_group.tg_sentry]
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
   
  default_action {
    target_group_arn = aws_alb_target_group.tg_sentry.arn
    type             = "forward"
  }
}
