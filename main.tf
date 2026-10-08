terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Creating a Docker Image ubuntu with the latest as the Tag.
resource "docker_image" "ubuntu" {
  name = "ubuntu:latest"
}


# Descargar la imagen oficial de Apache (httpd)
resource "docker_image" "apache_img" {
  name         = "httpd:latest"
  keep_locally = false
}

# Crear el contenedor de Apache
resource "docker_container" "apache_container" {
  image = docker_image.apache_img.image_id
  name  = "mi_servidor_apache_terraform"

  # Mapeo de puertos (8080 en el host -> 80 en el contenedor)
  ports {
    internal = 80
    external = 8080
  }
}
