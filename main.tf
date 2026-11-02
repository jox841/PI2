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
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # Conexión por defecto con el socket local de Docker en la máquina
}

# 0. VOLÚMENES PERSISTENTES (Para que no se borren datos al hacer destroy)
resource "docker_volume" "datos_mariadb" {
  name = "volumen-datos-mariadb"
}

resource "docker_volume" "datos_apache" {
  name = "volumen-datos-apache"
}

resource "docker_volume" "datos_grafana" {
  name = "volumen-datos-grafana"
}

# 1. DEFINICIÓN DE REDES
resource "docker_network" "red_backend" {
  name = "red-backend"
}

resource "docker_network" "red_monitoreo" {
  name = "red-monitoreo"
}

# 2. CONTENEDOR: MARIADB (Base de Datos con Volumen Persistente)
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
  
  # Persistencia de datos de MariaDB
  volumes {
    volume_name    = docker_volume.datos_mariadb.name
    container_path = "/var/lib/mysql"
  }
}

# 3. CONTENEDOR: APACHE (Servidor Web con Volumen Persistente)
resource "docker_container" "apache" {
  name  = "contenedor-apache"
  image = "httpd:latest"
  ports {
    internal = 80
    external = 8080
  }
  # Conectado a ambas redes: habla con la BD y permite que lo monitoreen
  networks_advanced {
    name = docker_network.red_backend.name
  }
  networks_advanced {
    name = docker_network.red_monitoreo.name
  }

  # Persistencia de los archivos web de Apache
  volumes {
    volume_name    = docker_volume.datos_apache.name
    container_path = "/usr/local/apache2/htdocs/"
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

  # Conecta tu archivo de configuración local con el contenedor
  volumes {
    host_path      = "${path.cwd}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

# 5. CONTENEDOR: GRAFANA (Visualización con Volumen Persistente)
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

  # Persistencia de configuraciones, paneles y usuarios de Grafana
  volumes {
    volume_name    = docker_volume.datos_grafana.name
    container_path = "/var/lib/grafana"
  }
}
