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
