variable "region" {
  default = "us-east-1"
}

variable "ami_id" {
  default = "ami-0c2b8ca1dad447f8a"  # Amazon Linux 2 AMI in us-east-1
}

variable "instance_type" {
  default = "t2.micro"
}
