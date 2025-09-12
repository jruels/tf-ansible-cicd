##Amazon Infrastructure
provider "aws" {
  region = var.aws_region
}

##Data source to get available AZs dynamically
data "aws_availability_zones" "available" {
  state = "available"
  
  # Filter out AZs that might not support all instance types
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

##Local values for dynamic AZ configuration with validation
locals {
  # Take first 2 available AZs, ensure we have at least 2
  azs = length(data.aws_availability_zones.available.names) >= 2 ? slice(data.aws_availability_zones.available.names, 0, 2) : data.aws_availability_zones.available.names
  
  # Validate we have enough AZs
  az_count = length(local.azs)
}

##Validation checks
check "availability_zones" {
  assert {
    condition     = local.az_count >= 2
    error_message = "At least 2 availability zones are required for this deployment. Found ${local.az_count} AZs in region ${var.aws_region}. Consider using a different region."
  }
}

##Create VPC using AWS VPC module with dynamic AZs
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "k8s-vpc"
  cidr = "10.0.0.0/16"

  azs             = local.azs
  public_subnets  = [for i in range(local.az_count) : "10.0.${i + 1}.0/24"]
  private_subnets = [for i in range(local.az_count) : "10.0.${i + 101}.0/24"]

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

##Debug outputs for troubleshooting
output "available_availability_zones" {
  description = "All available AZs in the region"
  value       = data.aws_availability_zones.available.names
}

output "selected_availability_zones" {
  description = "Selected AZs for deployment"
  value       = local.azs
}

output "vpc_public_subnets" {
  description = "Public subnet CIDRs"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "vpc_private_subnets" {
  description = "Private subnet CIDRs" 
  value       = module.vpc.private_subnets_cidr_blocks
}

##Application outputs
output "k8s-master-public_ips" {
  description = "Public IP addresses of Kubernetes master nodes"
  value = aws_instance.aws-k8s-master.*.public_ip
}

output "k8s-node-public_ips" {
  description = "Public IP addresses of Kubernetes worker nodes"
  value = aws_instance.k8s-members.*.public_ip
}

