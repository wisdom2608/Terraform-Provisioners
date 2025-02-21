resource "aws_key_pair" "my_key" {
  key_name   = "key"
  public_key = file("~/.ssh/my_key.pub")
}


data "aws_availability_zones" "available" {}

resource "aws_instance" "remote-exec_provisioner" {
  ami                    = "ami-xxxxxxxxxxxxxx"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  availability_zone      = data.aws_availability_zones.available.names[0]
  vpc_security_group_ids = [aws_security_group.provisioner_sg.id]
  tags = {
    Name = "Remote-Exec-Server"
  }
}

resource "null_resource" "remote-exec" {
  depends_on = [aws_instance.remote-exec_provisioner]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/my_key")
    host        = aws_instance.remote-exec_provisioner.public_ip # or host = aws_instance.file_provisioner.public_dns 
  }

  provisioner "remote-exec" {
  inline = ["chmod a+x script.sh",
  "bash ./script.sh"]
  }
}

