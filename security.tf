resource "aws_security_group" "load_balancer" {
  name        = "terraform-infra-nlb"
  description = "Allow public HTTP traffic to the network load balancer."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-infra-nlb-sg"
  }
}

resource "aws_security_group" "instances" {
  name        = "terraform-infra-instances"
  description = "Allow HTTP only from the network load balancer."
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from the network load balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-infra-instance-sg"
  }
}
