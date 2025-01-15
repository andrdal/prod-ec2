#Get Linux AMI ID using SSM Parameter
data "aws_ssm_parameter" "linuxsample-ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "linuxsample_profile" {
  name = "linuxsamples_profile"
  role = aws_iam_role.role.name
}

#Create and bootstrap linuxsample
resource "aws_iam_role" "role" {
  name = "linuxsamples_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

# Attach the AmazonEC2RoleforSSM policy
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# Attach the AmazonS3FullAccess policy
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


resource "aws_instance" "linuxsample" {
  ami                         = data.aws_ssm_parameter.linuxsample-ami.value
  instance_type               = "t3.micro"
  #key_name                    = aws_key_pair.linuxsample-key.key_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.private_subnets[0].id
  iam_instance_profile        = aws_iam_instance_profile.linuxsample_profile.name
  tags = {
    Name = "Linux-${var.environment_name}"
  }
}

output "private_ip_address" {
  value = aws_instance.linuxsample.private_ip
}

#Create key-pair for logging into EC2 in us-east-1
# resource "aws_key_pair" "linuxsample-key" {
#   key_name   = "linuxsample-key"
#   public_key = file("~/.ssh/ec2_instances_labs.pub")
# }

#Create SG for allowing TCP/80 & TCP/22
resource "aws_security_group" "sg" {
  name        = "SG-Linux-${var.environment_name}"
  description = "Allow TCP/80 & TCP/22"
  #vpc_id      = data.aws_vpc.targetVpc.id
  vpc_id       = aws_vpc.main.id
  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow traffic from TCP/80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow traffic from TCP/443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow icmp traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
