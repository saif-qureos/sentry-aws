output "sentry-endpoint" {
  value =  "https://${aws_route53_record.this.name}"
}
