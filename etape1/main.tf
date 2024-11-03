#Configurer le provider Docker

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.15"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}



# Création d'un réseau Docker nommé 'my_docker_network'
resource "docker_network" "my_network" {
  name = "my_docker_network"
}

# Téléchargement de l'image NGINX
resource "docker_image" "nginx_image" {
  name = "nginx:latest"
}

# Téléchargement de l'image PHP-FPM
resource "docker_image" "php_fpm_image" {
  name = "php:fpm"
}

# Configuration du conteneur NGINX
resource "docker_container" "nginx_container" {
  image = docker_image.nginx_image.name  # Utilisation du nom de l'image téléchargée
  name  = "nginx-http"
  
  # Redirection du port 80 (interne) vers 8080 (externe)
  ports {
    internal = 80
    external = 8080
  }
  
  # Associe le conteneur NGINX au réseau Docker créé précédemment
  networks_advanced {
    name = docker_network.my_network.name
  }
}

# Configuration du conteneur PHP-FPM
resource "docker_container" "php_fpm_container" {
  image = docker_image.php_fpm_image.name
  name  = "php-fpm"

  # Utilisation de path.module pour fournir un chemin absolu
  volumes {
    host_path = "/home/freddy/Documents/Cours_efrei/Mlops_DEVops/tp/tp_iac/app"
    container_path = "/app"
  }

  # Associe le conteneur PHP-FPM au réseau Docker
  networks_advanced {
    name = docker_network.my_network.name
  }
}
