variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "aws_profile" {
  type    = string
  default = "qureos-prod-terraform"
}

packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals { ami_suffix = "qureos-prod" }

source "amazon-ebs" "sentry" {
  ami_name      = "sentry-${local.ami_suffix}"
  profile       = "${var.aws_profile}"
  instance_type = "t2.large"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-bionic-18.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.sentry"]

  provisioner "file" {
    source      = "./the-keys.pub"
    destination = "/tmp/the-keys.pub"
  }
  provisioner "shell" {
    script = "./installer.sh"
  }
}
