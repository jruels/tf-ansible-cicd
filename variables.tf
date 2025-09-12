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
  default = 1
}

variable "aws_worker_count" {
  default = 2
}

variable "aws_key_name" {
  default = "ansible"
}

#variable "availability_zone" {
#  default = "us-west-1b"
#}

variable "aws_instance_size" {
  default = "t3.small"
}

variable "aws_region" {
  default = "us-west-1"
}


