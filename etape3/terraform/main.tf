provider "aws" {
  region = "eu-west-3"  # Remplace par ta région préférée
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    Name = "main-subnet"
  }
}

resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP on 8080"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

resource "aws_instance" "web" {
  count             = 2  # Une instance pour HTTP et une pour SCRIPT
  ami               = var.ami  # AMI Amazon Linux 2, vérifie la disponibilité dans ta région
  instance_type     = "t2.micro"
  subnet_id         = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  associate_public_ip_address = true  # Associe une IP publique
  key_name          = "myKey"  # Remplace par ta clé SSH

  tags = {
    Name = "web-${count.index + 1}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo yum install -y python3"  # Nécessaire pour Ansible
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/freddy/.aws/myKey.pem")  # Remplace par le chemin vers ta clé privée
      host        = self.public_ip
    }
  }
}

# Provision pour attendre que l'instance soit prête
resource "null_resource" "wait_for_instance" {
  provisioner "local-exec" {
    command = "sleep 60"  # Attente de 60 secondes pour s'assurer que l'instance est prête
  }
  depends_on = [aws_instance.web]
}

output "web_instance_ips" {
  value = aws_instance.web.*.public_ip
}

