# Main Application Server - Spring Boot + Redis

resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-main-eip"
  }
}

resource "aws_eip_association" "main" {
  instance_id   = aws_instance.main.id
  allocation_id = aws_eip.main.id
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.main_instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Wait for cloud-init
    sleep 10

    # Install Docker
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    usermod -aG docker ubuntu
    systemctl enable docker && systemctl start docker

    # Install Alloy for local metrics/logs collection
    mkdir -p /etc/apt/keyrings/
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
    echo 'deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main' | tee /etc/apt/sources.list.d/grafana.list
    apt-get update
    apt-get install -y alloy

    # Create directories
    mkdir -p /home/ubuntu/{app,redis,configs}
    chown -R ubuntu:ubuntu /home/ubuntu/{app,redis,configs}

    echo 'Main server setup complete' > /home/ubuntu/setup-complete.txt
  EOF

  tags = {
    Name        = "${var.prefix}-main-server"
    Environment = var.environment
    Role        = "application"
  }
}
