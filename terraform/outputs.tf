output "public_ip" {
  value = aws_instance.sentryserver.public_ip
}

output "public_dns" {
  value = aws_instance.sentryserver.public_dns
}
