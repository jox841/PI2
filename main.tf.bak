terraform {
  backend "remote" {
    organization = "PI-2-ASIR"

    workspaces {
      name = "PI2-Johann-Fran"
    }
  }

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
}


# 1. DEFINICIÓN DE REDES
resource "docker_network" "red_backend" {
  name = "red-backend"
}

resource "docker_network" "red_monitoreo" {
  name = "red-monitoreo"
}

# 2. CONTENEDOR: MARIADB (Base de Datos)
resource "docker_container" "mariadb" {
  name  = "contenedor-mariadb"
  image = "mariadb:latest"
  env = [
    "MYSQL_ROOT_PASSWORD=mi_clave_secreta",
    "MYSQL_DATABASE=mi_web_db"
  ]
  networks_advanced {
    name = docker_network.red_backend.name
  }
  # No exponemos puertos al host por seguridad, solo accesible por Apache
}

# 3. CONTENEDOR: APACHE (Servidor Web)
resource "docker_container" "apache" {
  name  = "contenedor-apache"
  image = "httpd:latest"
  ports {
    internal = 80
    external = 8080
=======
provider "aws" {
  region = var.aws_region
}

# Obtener la última AMI oficial de Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Grupo de Seguridad (Firewall)
resource "aws_security_group" "infra_sg" {
  name        = "proyecto_infra_sg"
  description = "Permitir trafico SSH, Web, Prometheus y Grafana"

  # Acceso SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Aplicación web principal (ej. puerto 80 o 8080)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus (Puerto por defecto 9090)
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana (Puerto por defecto 3000)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tráfico de salida libre
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instancia EC2 que actuará como nodo de despliegue
resource "aws_instance " "servidor_monotorizacion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.infra_sg.id]

  # Script de automatización (User Data) para instalar Docker y Docker Compose al arrancar
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              usermod -aG docker ubuntu
              systemctl start docker
              systemctl enable docker
              EOF

  tags = {
    Name = "Servidor-Proyecto-Intermodular"
>>>>>>> 6bdf13dd1522fe537d7a8b7af0bd2d360146666e
  }
  # Conectado a ambas redes: habla con la BD y permite que lo monitoreen
  networks_advanced {
    name = docker_network.red_backend.name
  }
  networks_advanced {
    name = docker_network.red_monitoreo.name
  }
}

# 4. CONTENEDOR: PROMETHEUS (Métricas)
resource "docker_container" "prometheus" {
  name  = "contenedor-prometheus"
  image = "prom/prometheus:latest"
  ports {
    internal = 9090
    external = 9090
  }
  networks_advanced {
    name = docker_network.red_monitoreo.name
  }

 # AÑADE ESTO: Conecta tu archivo local con el interior del contenedor
  volumes {
    host_path      = "${path.cwd}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}
# 5. CONTENEDOR: GRAFANA (Visualización)
resource "docker_container" "grafana" {
  name  = "contenedor-grafana"
  image = "grafana/grafana:latest"
  ports {
    internal = 3000
    external = 3000
  }
  networks_advanced {
    name = docker_network.red_monitoreo.name
  }
}
