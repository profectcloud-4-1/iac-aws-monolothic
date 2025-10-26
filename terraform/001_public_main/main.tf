provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "public_main" {
  ami           = "ami-03aa7eed9a19f1035" # custom ami: nginx 설치, ssh 포트 변경
  instance_type = "t2.micro"
  key_name      = "goorm_aws"

  subnet_id = "subnet-028f61bd9aac326b8"

  vpc_security_group_ids = [
    "sg-01d4cc79d1ebb6072", # http/https
    "sg-0c7959b289af6745f"  # ssh new port
  ]

  associate_public_ip_address = true

  # 종료 시 동작
  instance_initiated_shutdown_behavior = "terminate"

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    project = "goormdotcom"
  }
}

output "public_ip" {
  value = aws_instance.public_main.public_ip
}