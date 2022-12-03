terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "proute" {
  vpc_id = aws_vpc.myvpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
}

resource "aws_route_table_association" "proute_public_subnet" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.proute.id
}

resource "aws_security_group" "MyMainSG" {
  name          = "MyServer-SG"
  description   = "cool"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port     = 22
    to_port       = 22
    protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "testingserver" {
  ami           = "ami-094125af156557ca2"
  instance_type = "t2.nano"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.MyMainSG.id]
  key_name = "vockey"

  user_data = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install python3 -y
pip3 install --upgrade pip && pip3 install requests uvicorn FastAPI httpie
EOF
}
