variable "phase" {
  description = "init or post"
  default     = "init"
}
variable "ssh_private_key_path" {
  description = "Path to SSH private key for initial provisioning"
}

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "public_main" {
  ami           = "ami-00e73adb2e2c80366"
  instance_type = "t2.micro"
  key_name      = "goorm_aws"

  subnet_id = "subnet-028f61bd9aac326b8"

  vpc_security_group_ids = var.phase == "init" ? [
    "sg-01d4cc79d1ebb6072", # http/https
    "sg-0e44de3ecfdf0fa2a", # ssh 22
    "sg-0c7959b289af6745f"  # ssh new port
  ] : [
    "sg-01d4cc79d1ebb6072", # http/https
    "sg-0c7959b289af6745f"  # ssh new port only
  ]

  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    project = "goormdotcom"
  }
}

resource "null_resource" "wait_for_ssh" {
  count = var.phase == "init" ? 1 : 0

  triggers = {
    instance_id = aws_instance.public_main.id
    public_ip   = aws_instance.public_main.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || true",
      "echo ssh-ready"
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.public_main.public_ip
      user        = "ubuntu"
      private_key = file(pathexpand(var.ssh_private_key_path))
      port        = 22
      timeout     = "10m"
    }
  }

  depends_on = [aws_instance.public_main]
}

output "public_ip" {
  value = aws_instance.public_main.public_ip
}