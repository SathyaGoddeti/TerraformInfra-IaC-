variable "aws_region" {
  description = "AWS region in which to create the network."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type used by the Auto Scaling group."
  type        = string
  default     = "c7i-flex-large"
}
