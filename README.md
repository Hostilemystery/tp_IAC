# Projet Infrastructure as Code (IaC) avec Terraform - Étapes 1, 2 et 3

Ce projet utilise Terraform pour automatiser la configuration d'une infrastructure AWS, incluant la création de VPC, sous-réseaux, groupes de sécurité, et le déploiement d'instances EC2.

## Prérequis

1. **Terraform** doit être installé sur votre machine. Vous pouvez le télécharger à partir de [Terraform Downloads](https://www.terraform.io/downloads).
2. **AWS CLI** configurée avec vos identifiants AWS, ou renseignez vos credentials AWS dans le fichier `credentials` (`~/.aws/credentials`).
3. Un fichier de clé privée `.pem` pour l'accès SSH aux instances EC2, situé dans `~/.aws/myKey.pem`.

## Étape 1 : Création du VPC et du Sous-réseau

1. Créez un VPC avec un CIDR de `10.0.0.0/16`.
2. Dans ce VPC, créez un sous-réseau avec un CIDR de `10.0.1.0/24`.
3. Créez un groupe de sécurité permettant les connexions SSH (port 22) et HTTP (port 8080) depuis n'importe quelle IP publique.

### Fichier Terraform pour l'étape 1 (main.tf)

```hcl
provider "aws" {
  region = "eu-west-3" # Spécifiez la région AWS
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
}

resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
```

## Étape 2 : Déploiement des Instances EC2

1. Déployez deux instances EC2 dans le sous-réseau configuré dans l'étape 1.
2. Assignez le groupe de sécurité créé précédemment pour autoriser les connexions SSH et HTTP.
3. Assurez-vous que les instances ont des adresses IP publiques pour un accès externe.

### Fichier Terraform pour l'étape 2 (main.tf)

Ajoutez la configuration suivante dans le même fichier `main.tf` :

```hcl
resource "aws_instance" "web" {
  count             = 2
  ami               = "ami-06ea722eac9a555ff" # AMI Amazon Linux 2
  instance_type     = "t2.micro"
  subnet_id         = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  key_name          = "myKey" # Remplacez par votre clé

  tags = {
    Name = "web-${count.index + 1}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.aws/myKey.pem")
      host        = self.public_ip
    }
  }
}
```

## Étape 3 : Configuration avec `null_resource` pour un délai d'attente

Certaines instances peuvent nécessiter un temps de démarrage avant que SSH soit prêt. Utilisez un `null_resource` pour ajouter un délai avant de continuer.

### Fichier Terraform pour l'étape 3 (main.tf)

Ajoutez la ressource suivante pour ajouter un délai d'attente :

```hcl
resource "null_resource" "wait_for_instance" {
  provisioner "local-exec" {
    command = "sleep 60"
  }
  depends_on = [aws_instance.web]
}
```

## Exécution des étapes avec Terraform

1. Initialisez le projet Terraform :

   ```bash
   terraform init
   ```

2. Appliquez la configuration Terraform :

   ```bash
   terraform apply
   ```

3. Validez que les instances EC2 sont créées et accessibles via SSH en utilisant la commande suivante (en remplaçant `<public_ip>` par l'adresse IP publique de l'instance) :
   ```bash
   ssh -i ~/.aws/myKey.pem ec2-user@<public_ip>
   ```

## Nettoyage

Pour détruire les ressources créées par Terraform, exécutez :

```bash
terraform destroy
```
