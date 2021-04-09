variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.1.0.0/24"
}

variable "cidr_subnet2" {
  description = "CIDR block for the subnet 2"
  default     = "10.1.1.0/24"
}

variable "environment_tag" {
  description = "Environment tag"
  default     = "Sentry"
}

variable "keypath" {
  description = "The address for private key"
  default = "../packer/the-keys"
}

variable "domain_name" {
  description = "The name of your domain"
  default = "thedomain.lcl"
}

variable "certificate_arn" {
    description = "The certificate ARN for webserver and load balancer"
    default = "arn:aws:acm:us-east-1:188356072928:certificate/4c8a078f-f1b6-405e-bc20-bfae2e86d6ff"
}

variable "region" {
  description = "Deployment Region"
  default = "us-east-1"
}

variable "ami_id" {
  description = "The Newly created AMI from Packer"
  default = "ami-0b9efb38af082868d"
}
