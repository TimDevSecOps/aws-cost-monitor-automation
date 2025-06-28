provider "aws" {
  region = var.region
}

resource "aws_instance" "my_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name = "tim-labs-ec2-tf"
  }
}

resource "aws_ebs_volume" "data_volume" {
  availability_zone = aws_instance.my_ec2.availability_zone
  size              = 1
  type              = "gp2"

  tags = {
    Name = "tim-labs-1gb-vol"
  }
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdk"
  volume_id   = aws_ebs_volume.data_volume.id
  instance_id = aws_instance.my_ec2.id
  force_detach = true
}