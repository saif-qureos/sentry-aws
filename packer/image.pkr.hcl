variable "region" {
  type    = string
  default = "us-east-1"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "sentry" {
  ami_name      = "sentry-${local.timestamp}"
  instance_type = "t2.medium"
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
