##Amazon Infrastructure
provider "aws" {
  region = var.aws_region
}

##Create VPC using AWS VPC module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "k8s-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "k8s-vpc"
    Environment = "development"
  }
}

##Create k8s security group
resource "aws_security_group" "k8s_sg" {
  name        = "k8s_sg"
  vpc_id      = module.vpc.vpc_id
  description = "Allow all inbound traffic necessary for k8s"
  depends_on  = [module.vpc]
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
  tags = {
    Name = "k8s_sg"
  }
}

##Find latest Ubuntu AMI
data "aws_ami" "ubuntu" {
most_recent = true
# owners      = ["xxxxxx"]  # Canonical's AWS account ID
owners      = ["amazon"]

filter {
name   = "name"
values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
}

filter {
name   = "virtualization-type"
values = ["hvm"]
 }
}

##Create k8s Master Instance
resource "aws_instance" "aws-k8s-master" {
  subnet_id              = module.vpc.public_subnets[0]
  depends_on             = [aws_security_group.k8s_sg]
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.aws_instance_size
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.aws_key_name
  count                  = var.aws_master_count
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
  tags = {
    Name = "k8s-master-${count.index}"
    role = "k8s-master"
  }
}

##Create AWS k8s Workers
resource "aws_instance" "k8s-members" {
  subnet_id              = module.vpc.public_subnets[0]
  depends_on             = [aws_security_group.k8s_sg]
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.aws_instance_size
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.aws_key_name
  count                  = var.aws_worker_count
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
  tags = {
    Name = "k8s-member-${count.index}"
    role = "k8s-member"
  }
}

output "k8s-master-public_ips" {
  value = [aws_instance.aws-k8s-master.*.public_ip]
}

output "k8s-node-public_ips" {
  value = [aws_instance.k8s-members.*.public_ip]
}

