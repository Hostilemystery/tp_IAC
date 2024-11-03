variable "region" {
  description = "AWS region"
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "myKey"
  type        = string
}

variable "ami" {
  description = "AMI ID for EC2 instances"
  default     = "ami-06ea722eac9a555ff"  # Amazon Linux 2
}

