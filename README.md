In every time we provision a new set of cloud infrastructure, there is a purpose behind it.

For example, when we create an EC2 instance, we create it to accomplish certain tasks – executing heavy workloads, acting as a bastion host, or simply serving as the frontend for all incoming requests. To enable it to function, this instance needs more actions like installing a web server, applications, databases, setting network firewall, etc.

Terraform is a great IaC tool that helps us build infrastructure using code. Additionally, when the EC2 instance boots or is destroyed, it is also possible to perform some of the above tasks using provisioners in Terraform. In this post, we will explore the scenarios handled by provisioners, how they are implemented, and preferable ways to do it.

**What is a Terraform provisioner?**
Terraform provisioners have nothing in common with providers, they allow the execution of various commands or scripts on either *local or remote machines*, and they can also transfer files from a local environment to a remote one. There are three available provisioners: file (used for copying), local-exec (used for local operations), remote-exec (used for remote operations). The *file and remote-exec provisioners need a connection block* to be able to do the remote operations.

Provisioning mainly deals with configuration activities that happen after the resource is created. It may involve some file operations, executing CLI commands, or even executing the script. Once the resource is successfully initialized, it is ready to accept connections. These connections help Terraform log into the newly created instance and perform these operations.

It is worth noting that using Terraform provisioners for the activities described in this post should be considered as a last resort. The main reason is the availability of dedicated tools and platforms that align well with the use cases discussed in this post. Hashicorp suggests Terraform provisioners should only be considered when there is no other option.

**What is the difference between Terraform null resource and provisioner?**
A Terraform null resource is a special resource that doesn’t create any infrastructure. It is the predecessor of terraform_data, and it acts as a mechanism to trigger actions based on input changes. It can be used together with provisioners to achieve different operations that are configured in them.

What is the difference between User_data and provisioner in Terraform?
User_data allows users to provide initialization scripts or configuration details that the instance uses upon startup via cloud-init. The user_data script runs only once when the bootstrap of the instance is done. Provisioners, however, can run multiple times, based on the declared configuration.

**Terraform provider vs provisioner**
Terraform providers are plugins used to authenticate with cloud platforms, services or other tools, allowing users to create, modify, and delete resources declared in the Terraform configurations. In Terraform, 𝐏𝐫𝐨𝐯𝐢𝐬𝐢𝐨𝐧𝐞𝐫𝐬 are a set of built-in functionalities that allow you to execute scripts, commands, or other configuration actions on remote resources after they’ve been created or destroyed. Provisioners are often used for tasks like initializing software, configuring instances, or performing post-deployment setup. There are different types of provisioners in Terraform, each serving a specific purpose. 

**Terraform provisioners types**
There are three types of provisioners in Terraform: 

- *File provisioners*
- *Local-exec provisioners*
- *Remote-exec provisioners*

1. **File Provisioners**
The `file` provisioner allows you to copy files or directories from the local machine to a remote resource after it’s created. This provisioner is useful for transferring configuration files, scripts, or other assets to a remote instance.
This requires connection between the local machine and the remote server either through `ssh` in the case of a remote linux server, or `WinRM` in the case of a remote windows machine.

**Example**

```bash

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

```
2. **Local-Exec Provisioners**
The `local-exec` provisioner allows you to run commands or scripts on the machine where Terraform is executed, typically your local development machine or a CI/CD server. This provisioner is often used for tasks that don’t require access to the remote resource. That is, it does not require *connection* to the remote resource.

**Example**

```bash

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

```


3. **Remote-Exec Provisioner**

The `remote-exec` provisioner allows you to run commands or scripts on a remote resource over SSH or WinRM after the resource is created. This provisioner is commonly used for tasks like software installations and configuration on remote instances.

**Example**

```bash

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

resource "null_resource" "execute_commands" {
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

```

**File Provisioner, Local-Exec Provisioner, and Remote-Exec Provisioner on the same terraform configuration file** 

`Connection block` is configured out of provisioner block so as to avoid multiple connection configurations within provisioners that requires access to remote resoures. Follow the subsequence steps:

**Step 1**: create a `provider.tf` file

```bash

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "<Your-S3-Bucket_Name>"
    key    = "Terraform_provisioners/terraform.tfstate"
    region = "Your_region"
  }
}

provider "aws" {
  region = "Your_region"
}

```
**Step 2**: Create a `vpc.tf` file. In this case, we are using the *default vpc*

```bash
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

```
**Step 3**: Create a `security_groups.tf` file

```bash
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
    Name = "Terraform-Provisioner-SG"
  }
}

```

**Step 4**: Create an `iam_role.tf` file. This role has policies that allow your resources to interact with your s3 bucket(s) securely.

```bash

# IAM Role
resource "aws_iam_role" "provisioner_role" {
  name        = "file_provisioner_role"
  description = "iam role for terraform provisioners"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonS3FullAccess policy
resource "aws_iam_role_policy_attachment" "s3_fullaccess" {
  role       = aws_iam_role.provisioner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


# Create Instance Profile
resource "aws_iam_instance_profile" "instance_provisioner_role" {
  name = "Test-Instance-Profile"
  role = aws_iam_role.provisioner_role.name
}
```

**Step 5**: Create a `main.tf` file.

```bash

resource "aws_key_pair" "my_key" {
  key_name   = "key"
  public_key = file("~/.ssh/my_key.pub")
}


data "aws_availability_zones" "available" {}

resource "aws_instance" "provisioner_instance" {
  ami                    = "ami-xxxxxxxxxxxxxx"
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
    command = "echo ${aws_instance.provisioner_instance.public_ip} >> public_ip.txt"

  }
  provisioner "remote-exec" {
    inline = ["chmod a+x script.sh",
    "bash ./script.sh"]
  }
}

```

**Step 6**: Create a `script.sh` bash script within your project directory. The script is for ubuntu machine.

```bash

#!/bin/bash/

# Update the Package Index
sudo apt-get update

# Install AWSCL to list s3 buckets
# - Install Dependencies
sudo apt install -y unzip curl \
&& curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# - Extract the Installer
unzip awscliv2.zip
# - Run the installation script
sudo ./aws/install 
# - Remove the zipped downloaded files to free up space
rm -rf awscliv2.zip aws
# - Install Apache Sever
sudo apt install apache2 -y
# - Enable Apache Sever
sudo systemctl enable apache2
# - Start Apache Sever
sudo systemctl start apache2
# - Pull src code from S3 to your remote server
sudo aws s3 sync s3://<your_s3_bucket_name> .
# - Copy src code contents to apache 2 directory 
sudo cp <name_of_the_folder_sync_from_s3_bucket>/* /var/www/html
# - Restart Apache Sever
sudo systemctl restart apache2

```