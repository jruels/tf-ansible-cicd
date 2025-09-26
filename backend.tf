terraform {
  backend "s3" {
    bucket = "tf-ansible-cicd-state--usw2-az1--x-s3"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}
