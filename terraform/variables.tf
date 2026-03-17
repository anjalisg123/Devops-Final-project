variable "aws_region" {
  default = "us-east-1"
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID for us-east-2"
  default     = "ami-0b0b78dcacbab728f"
}

variable "key_name" {
  description = "EC2 key pair name"
}

variable "docker_image" {
  description = "Docker image to deploy"
}