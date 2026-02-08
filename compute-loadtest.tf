# Load Test Server - K6, Locust (on/off via enable_loadtest)

resource "aws_eip" "loadtest" {
  count  = var.enable_loadtest ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-loadtest-eip"
  }
}

resource "aws_eip_association" "loadtest" {
  count         = var.enable_loadtest ? 1 : 0
  instance_id   = aws_instance.loadtest[0].id
  allocation_id = aws_eip.loadtest[0].id
}

resource "aws_instance" "loadtest" {
  count                  = var.enable_loadtest ? 1 : 0
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.loadtest_instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.loadtest.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Wait for cloud-init
    sleep 10

    apt-get update

    # Install K6
    gpg -k
    gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
    echo 'deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main' | tee /etc/apt/sources.list.d/k6.list
    apt-get update
    apt-get install -y k6

    # Install Python and Locust
    apt-get install -y python3 python3-pip
    pip3 install locust

    # Install Apache Bench
    apt-get install -y apache2-utils

    # Create directories
    mkdir -p /home/ubuntu/{k6-scripts,locust-scripts,results}
    chown -R ubuntu:ubuntu /home/ubuntu/{k6-scripts,locust-scripts,results}

    echo 'Load test server setup complete' > /home/ubuntu/setup-complete.txt
  EOF

  tags = {
    Name        = "${var.prefix}-loadtest-server"
    Environment = var.environment
    Role        = "loadtest"
  }
}
