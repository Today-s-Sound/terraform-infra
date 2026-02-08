# Monitoring Server - Prometheus, Grafana, Loki, Alloy

resource "aws_eip" "monitoring" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-monitoring-eip"
  }
}

resource "aws_eip_association" "monitoring" {
  instance_id   = aws_instance.monitoring.id
  allocation_id = aws_eip.monitoring.id
}

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.monitoring_instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  root_block_device {
    volume_size = 50
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

    # Create directories
    mkdir -p /home/ubuntu/{scripts,docker,configs}
    chown -R ubuntu:ubuntu /home/ubuntu/{scripts,docker,configs}

    echo 'Monitoring server setup complete' > /home/ubuntu/setup-complete.txt
  EOF

  tags = {
    Name        = "${var.prefix}-monitoring-server"
    Environment = var.environment
    Role        = "monitoring"
  }
}
