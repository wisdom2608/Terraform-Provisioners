resource "aws_key_pair" "my_key" {
  key_name = "key"
  public_key = file("~/.ssh/my_key.pub")
}


data "aws_availability_zones" "available" {}

resource "aws_instance" "file_provisioner" {
  ami                    = "ami-xxxxxxxxxxxxxxx"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  availability_zone      = data.aws_availability_zones.available.names[0]
  vpc_security_group_ids = [aws_security_group.provisioner_sg.id]
  tags = {
    Name = "File-Server"
  }
}

resource "null_resource" "copy_file_on_vm" {
  depends_on = [ aws_instance.file_provisioner ]

connection {
  type = "ssh"
  user = "ubuntu"
  private_key = file("~/.ssh/my_key")
  host = aws_instance.file_provisioner.public_ip # or host = aws_instance.file_provisioner.public_dns 
}

provisioner "file" {
  source = "./script.sh"
  destination = "/home/ubuntu/script"
}
}