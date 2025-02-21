
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

# Attach AmazonS3ReadOnlyAccess policy
resource "aws_iam_role_policy_attachment" "s3_readOnlyacccess" {
  role       = aws_iam_role.provisioner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Attach AmazonSSMManagedInstanceCore policy
resource "aws_iam_role_policy_attachment" "ssm_manage_instance" {
  role       = aws_iam_role.provisioner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create Instance Profile
resource "aws_iam_instance_profile" "instance_provisioner_role" {
  name = "Test-Instance-Profile"
  role = aws_iam_role.provisioner_role.name
}

