data "aws_availability_zones" "available" {} 

resource "aws_instance" "local-exec_provisioner" {
  ami                    = "ami-xxxxxxxxxxxxxxxxx"
  instance_type          = "t2.micro"
  availability_zone      = data.aws_availability_zones.available.names[0]
  vpc_security_group_ids = [aws_security_group.provisioner_sg.id]
  tags = {
    Name = "Local-Exec-Server"
  }
}

resource "null_resource" "local_exec" {
  depends_on = [aws_instance.local-exec_provisioner]

  provisioner "local-exec" {
    command = "echo ${aws_instance.local-exec_provisioner.public_ip} >> public_ip.txt"
  }
}