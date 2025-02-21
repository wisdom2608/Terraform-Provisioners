
resource "aws_key_pair" "my_key" {
  key_name   = "key"
  public_key = file("~/.ssh/my_key.pub")
}


data "aws_availability_zones" "available" {}

resource "aws_instance" "provisioner_instance" {
  ami                    = "ami-xxxxxxxxxxxxxxxxxxx"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  availability_zone      = data.aws_availability_zones.available.names[0]
  vpc_security_group_ids = [aws_security_group.provisioner_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.instance_provisioner_role.name
  tags = {
    Name = "Tf-Provisioner-Server"
  }
}

resource "null_resource" "terraform_provisioners" {
  depends_on = [aws_instance.provisioner_instance]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/my_key")
    host        = aws_instance.provisioner_instance.public_ip # or host = aws_instance.file_provisioner.public_dns 
  }

  provisioner "file" {
    source      = "./script.sh"
    destination = "/home/ubuntu/script.sh"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.provisioner_instance.public_ip} and ${aws_instance.provisioner_instance.public_dns} >> public_ip.tx"

  }
  provisioner "remote-exec" {
    inline = ["chmod a+x script.sh",
    "bash ./script.sh"]
  }
}

# output "instance-ip" {
#   value = aws_instance.provisioner_instance.public_dns
# }

# output "instance-public_dns" {
#   value = aws_instance.provisioner_instance.public_ip
# }

