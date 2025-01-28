resource "aws_security_group" "allow_ssh_access" {
  name        = "allow_ssh_access"
  description = "Allow ssh access"

  ingress {
    description = "My_Access_Here"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["MYIP/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_access"
  }
}

