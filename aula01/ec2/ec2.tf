resource "aws_instance" "workstation" {
  ami           = "ami-0e999cbd62129e3b8"
  instance_type = "t2.micro"
  key_name      = "keypar"
  subnet_id     = "subned_id" 

  security_groups = [aws_security_group.allow_ssh_access.id]

  tags = {
    Name = "workstation"
  }
}


