resource "aws_eip" "this" {
  count  = var.create_eip ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.tags["Name"]}-eip"
  }
}

resource "aws_eip_association" "this" {
  count         = var.create_eip ? 1 : 0
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.sg_ids
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = var.user_data

  tags = var.tags
}
