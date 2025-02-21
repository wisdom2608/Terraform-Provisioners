

resource "aws_security_group" "provisioner_sg" {
  name        = "file_provisioner-sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "Enable SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
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
    Name = "Terraform-Provisioners-SG"
  }
}