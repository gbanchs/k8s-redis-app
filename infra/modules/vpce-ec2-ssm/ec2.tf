# data "aws_ami" "linux-ami" {
#   #name = "ami-0bbc0801b3da5b7ae"
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-amd-hvm-*-x86_64-gp2"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
#   most_recent = true
#   owners      = ["amazon"]
# }

# data "aws_ami" "bastion" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"]
# }

resource "aws_instance" "app-server" {
  instance_type = "t3.small"
  ami           = var.aws_image_id == "" ? "ami-0bbc0801b3da5b7ae" : var.aws_image_id
  #data.aws_ami.linux-ami.id
  vpc_security_group_ids      = [var.instance_sg]
  subnet_id                   = var.private_subnets[0]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  tags = merge(var.tags, {
    "Name" = "${var.name}"
  })
  user_data_base64 = base64encode(var.user_data)

  user_data_replace_on_change = false

}
