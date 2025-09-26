##General vars
variable "ssh_user" {
  default = "ubuntu"
}

variable "public_key_path" {
  default = "/Users/jruels/.ssh/k8s-test.pub"
}

variable "private_key_path" {
  default = "/Users/jruels/.ssh/k8s-test"
}



##AWS Specific Vars
variable "aws_master_count" {
  description = "Number of Kubernetes master nodes"
  type        = number
  default     = 1
  
  validation {
    condition     = var.aws_master_count >= 1 && var.aws_master_count <= 3
    error_message = "Master count must be between 1 and 3."
  }
}

variable "aws_worker_count" {
  description = "Number of Kubernetes worker nodes"
  type        = number
  default     = 2
  
  validation {
    condition     = var.aws_worker_count >= 1 && var.aws_worker_count <= 10
    error_message = "Worker count must be between 1 and 10."
  }
}

variable "aws_key_name" {
  description = "Name of the AWS EC2 Key Pair for SSH access"
  type        = string
  default     = "ansible"
}

#variable "availability_zone" {
#  default = "us-west-1b"
#}

variable "aws_instance_size" {
  default = "t3.medium"
}

variable "aws_region" {
  description = "AWS region for deployment. Must have at least 2 availability zones."
  type        = string
  default     = "us-west-2"
  
  validation {
    condition = can(regex("^[a-z]{2}-(north|south|east|west|central)-[0-9]$", var.aws_region))
    error_message = "AWS region must be in format: us-west-2, eu-west-1, etc."
  }
}


