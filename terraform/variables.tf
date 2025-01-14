variable "environment_tag" {
  description = "Environment tag"
  default     = "staging"
}

variable "is_private" {
  description = "Are the resources private and the connection should be private or not? If you select true make sure you are connected via VPN"
  default = true
  type = bool
}
variable "keypath" {
  description = "The address for private key"
  default = "../packer/the-keys"
}

variable "region" {
  description = "Deployment Region"
  default = "eu-west-1"
}

variable "private_subnet_ids" {
  description = "(Required) IDs of the subnets to which the services and database will be deployed"
}

variable "public_subnet_ids" {
  description = "(Required) IDs of the subnets to which the load balancer will be deployed"
}

variable "instance_type" {
  description = "(Required) Instance type to be deployed"
}

variable "healthcheck_path" {
  description = "(Required) healthcheck path for sentry"
  default = "/auth/login/sentry/"
}

variable "domain" {
  description = "(Required) Domain where metabase will be hosted. Example: metabase.mycompany.com"
}

variable "zone_id" {
  description = "(Required) https://www.terraform.io/docs/providers/aws/r/route53_record.html#zone_id"
}

variable "certificate_arn" {
  description = "(Required) https://www.terraform.io/docs/providers/aws/r/lb_listener.html#certificate_arn"
}

variable "ami_id" {
  description = "(Required) AMI ID exported from Packer"
}

variable "vpc_id" {
  description = "(Required) https://www.terraform.io/docs/providers/aws/r/security_group.html#vpc_id"
}

variable "id" {
  description = "(Optional) Unique identifier for naming resources"
  default     = "sentry"
}

variable "tags" {
  description = "(Optional) Tags applied to all resources"
  default     = {}
}

variable "max_capacity" {
  description = "(Optional) https://www.terraform.io/docs/providers/aws/r/rds_cluster.html#max_capacity"
  default     = "16"
}

variable "log_retention" {
  description = "(Optional) Retention period in days for both ALB and container logs"
  default     = "90"
}

variable "protection" {
  description = "(Optional) Protect ALB and application logs from deletion"
  default     = false
}

variable "internet_egress" {
  description = "(Optional) Grant internet access to the Metabase service"
  default     = true
}

variable "ssl_policy" {
  description = "(Optional) https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-policy-table.html"
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "snapshot_identifier" {
  description = "(Optional) https://www.terraform.io/docs/providers/aws/r/rds_cluster.html#snapshot_identifier"
  default     = ""
}

variable "environment" {
  description = "(Optional) Additional container environment variables"
  default     = []
}

variable "java_timezone" {
  description = "(Optional) https://www.metabase.com/docs/v0.21.1/operations-guide/running-metabase-on-docker.html#setting-the-java-timezone"
  default     = "US/Pacific"
}

variable "db_cluster_parameter_group_name" {
  description = "(Optional) https://www.terraform.io/docs/providers/aws/r/rds_cluster.html#db_cluster_parameter_group_name"
  default     = ""
}

variable "auto_pause" {
  description = "(Optional) https://www.terraform.io/docs/providers/aws/r/rds_cluster.html#auto_pause"
  default     = false
}

variable "db_name" {
  description = "(Required) Database Name"
}

variable "db_user" {
  description = "(Required) Database User"
}

variable "db_password" {
  description = "(Required) Database Password"
}

variable "aws_profile" {
  description = "(Required) AWS Profile to use."
}

variable "aws_s3_backend_bucket_name" {
  description = "(Required) AWS S3 Backend Bucket Name to use."
}
