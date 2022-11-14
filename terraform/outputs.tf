output "instance_private_ip" {
  value = var.is_private ? aws_instance.sentryserver.private_ip : aws_instance.sentryserver.public_ip
}

output "sentry-endpoint" {
  value =  "https://${aws_route53_record.this.name}"
}
