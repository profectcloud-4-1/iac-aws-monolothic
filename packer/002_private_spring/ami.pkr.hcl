packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  default = "ap-northeast-2"
}

variable "subnet_id" {}
variable "ssh_new_port" {}
variable "ssh_key_path" {}

# ebs 기반 ami 생성
source "amazon-ebs" "ubuntu" {
  region                  = var.region
  subnet_id               = var.subnet_id
  instance_type           = "t3.micro"
  ami_name                = "ubuntu-24-private-{{timestamp}}"
  # 베이스 이미지 선택
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    # 어떤 계정이 소유한 이미지를 검색할지 (= Canonical의 AWS 계정 ID)
    owners      = ["099720109477"]
    # 가장 최신 이미지 사용
    most_recent = true
  }
  ssh_username            = "ubuntu"

  # AWS 콘솔에 등록된 키페어 이름
  ssh_keypair_name        = "goorm_aws"
  # 로컬 키 파일 경로
  ssh_private_key_file    = var.ssh_key_path

  # public ip 자동할당
  associate_public_ip_address = true
}

build {
  name    = "private_spring"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "bash -lc 'echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
    ]
  }
}
