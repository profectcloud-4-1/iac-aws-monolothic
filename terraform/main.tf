variable "SSH_NEW_PORT" {
  description = "Custom SSH port for inbound access"
  type        = number
}

provider "aws" {
  region = "ap-northeast-2"
}

# vpc
resource "aws_vpc" "main" {
  cidr_block  = "10.9.0.0/16"
  # vpc 내부 인스턴스가 aws의 내부 dns 서버를 사용
  enable_dns_support  = true

  tags = {
    Name  = "goorm-vpc"
    project = "gooormdotcom"
  }
}

# subnet - public
resource "aws_subnet" "public"  { 
    vpc_id = aws_vpc.main.id
    cidr_block  = "10.9.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-2a"

    tags = {
      Name = "goorm-subnet-public"
      project = "goormdotcom"
    }
}

# subnet - private
resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block  = "10.9.2.0/24"
    availability_zone = "ap-northeast-2a"

    tags = {
      Name = "goorm-subnet-private"
      project = "goormdotcom"
    }
}

# internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "goorm-igw"
    project = "goormdotcom"
  }
}

# elastic ip & nat
resource "aws_eip" "nat" { 
  domain = "vpc" 

  tags = {
    Name    = "goorm-eip-nat"
    project = "goormdotcom"
  }
}
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.main]  # IGW가 먼저 생성되어야 함

  tags = {
    Name    = "goorm-nat"
    project = "goormdotcom"
  }
}

# route table - public
resource "aws_route_table" "public"  { 
  vpc_id = aws_vpc.main.id 

  tags = {
    Name    = "goorm-rtb-public"
    project = "goormdotcom"
  }
}
resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# route table - private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "goorm-rtb-private"
    project = "goormdotcom"
  }
}
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gw.id
}

# 서브넷 <-> 라우팅 테이블 연결
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# nacl - public
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name    = "goorm-nacl-public"
    project = "goormdotcom"
  }
}

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id

  # 인바운드: 퍼블릭 서브넷에서 SSH 허용
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = aws_subnet.public.cidr_block
    from_port  = 22
    to_port    = 22
  }

  # 인바운드: 퍼블릭 서브넷에서 HTTP 허용
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = aws_subnet.public.cidr_block
    from_port  = 80
    to_port    = 80
  }

  # 인바운드: 리턴 트래픽 허용 (1024~65535)
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }



  # 아웃바운드: 퍼블릭 서브넷으로 SSH 허용
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = aws_subnet.public.cidr_block
    from_port  = 22
    to_port    = 22
  }

  egress {
    rule_no    = 101
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  egress {
    rule_no    = 102
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # 아웃바운드: 퍼블릭 서브넷으로 HTTP 허용
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = aws_subnet.public.cidr_block
    from_port  = 80
    to_port    = 80
  }

  # 아웃바운드: 리턴 트래픽 허용 (ephemeral)
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name    = "goorm-nacl-private"
    project = "goormdotcom"
  }
}

# 서브넷 <-> NACL 연결
resource "aws_network_acl_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  network_acl_id = aws_network_acl.public.id
}
resource "aws_network_acl_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  network_acl_id = aws_network_acl.private.id
}

# security group

# SG1: HTTP/HTTPS (Public EC2용)
resource "aws_security_group" "public_web" {
  name        = "goorm-sg-public-web"
  description = "Allow HTTP/HTTPS inbound for public EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "goorm-sg-public-web"
    project = "goormdotcom"
  }
}

# SG2: SSH(New Port) (Public EC2용)
resource "aws_security_group" "public_ssh_new" {
  name        = "goorm-sg-public-ssh-new"
  description = "Allow SSH on custom port from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Custom SSH Port"
    from_port   = var.SSH_NEW_PORT
    to_port     = var.SSH_NEW_PORT
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "goorm-sg-public-ssh-new"
    project = "goormdotcom"
  }
}

# SG3: SSH(22) (Private EC2용, source = SG2)
resource "aws_security_group" "private_ssh" {
  name        = "goorm-sg-private-ssh"
  description = "Allow SSH(22) from public SSH SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from public SSH SG"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.public_ssh_new.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "goorm-sg-private-ssh"
    project = "goormdotcom"
  }
}

# SG4: HTTP (Private EC2용, source = SG1)
resource "aws_security_group" "private_http" {
  name        = "goorm-sg-private-http"
  description = "Allow HTTP from public web SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from public web SG"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "goorm-sg-private-http"
    project = "goormdotcom"
  }
}

# vpc endpoint: private subnect -> s3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "s3-gateway-endpoint"
    project = "goormdotcom"
  }
}

# ec2 - public
resource "aws_instance" "public_main" {
  ami           = "ami-053e0a41207f3dff0" # custom ami: nginx 설치, ssh 포트 변경
  instance_type = "t2.micro"
  key_name      = "goorm_aws"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.public_web.id,
    aws_security_group.public_ssh_new.id
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

# ec2 - private
resource "aws_instance" "private_spring" {
  ami           = "ami-0eb6e9cfa5591c469" # custom ami: docker 설치
  instance_type = "t2.micro"
  key_name      = "goorm_aws"

  subnet_id = aws_subnet.private.id

  vpc_security_group_ids = [
    aws_security_group.private_ssh.id,
    aws_security_group.private_http.id
  ]

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

# public EC2의 퍼블릭 IP 출력
output "public_ec2_public_ip" {
  description = "Public IP address of the public EC2 instance"
  value       = aws_instance.public_main.public_ip
}

# private EC2의 프라이빗 IP 출력
output "private_ec2_private_ip" {
  description = "Private IP address of the private EC2 instance"
  value       = aws_instance.private_spring.private_ip
}