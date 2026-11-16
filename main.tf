# 0. VOLÚMENES PERSISTENTES (se conservan aunque se borren los contenedores)
resource "docker_volume" "datos_mariadb" {
  name = "volumen-datos-mariadb"
}

resource "docker_volume" "datos_grafana" {
  name = "volumen-datos-grafana"
}

# 1. REDES
resource "docker_network" "red_backend" {
  name = "red-backend"
}

resource "docker_network" "red_monitoreo" {
  name = "red-monitoreo"
}

# 2. MARIADB
resource "docker_container" "mariadb" {
  name  = "contenedor-mariadb"
  image = "mariadb:11"
  env = [
    "MYSQL_ROOT_PASSWORD=${var.db_root_password}",
    "MYSQL_DATABASE=${var.db_name}",
    "MYSQL_USER=${var.db_user}",
    "MYSQL_PASSWORD=${var.db_password}"
  ]

  # Script de inicialización: crea las tablas al primer arranque
  upload {
    file    = "/docker-entrypoint-initdb.d/init.sql"
    content = file("${path.cwd}/sql/init.sql")
  }

  networks_advanced {
    name = docker_network.red_backend.name
  }

  volumes {
    volume_name    = docker_volume.datos_mariadb.name
    container_path = "/var/lib/mysql"
  }
}
# EXPORTER DE MARIADB (traduce el estado de la BD a métricas de Prometheus)
resource "docker_container" "mysqld_exporter" {
  name  = "contenedor-mysqld-exporter"
  image = "prom/mysqld-exporter:v0.16.0"

  command = ["--config.my-cnf=/etc/mysqld_exporter.cnf"]

  # Credenciales para conectar a MariaDB
  upload {
    file    = "/etc/mysqld_exporter.cnf"
    content = <<-EOT
      [client]
      user=root
      password=${var.db_root_password}
      host=contenedor-mariadb
      port=3306
    EOT
  }

  # Necesita ver a MariaDB (red-backend) y ser visto por Prometheus (red-monitoreo)
  networks_advanced {
    name = docker_network.red_backend.name
  }
  networks_advanced {
    name = docker_network.red_monitoreo.name
  }

  depends_on = [docker_container.mariadb]
}

# 3. APACHE (web en carpeta local + mod_status para el exporter)
resource "docker_container" "apache" {
  name  = "contenedor-apache"
  image = "httpd:2.4"

  # Activa /server-status y arranca Apache
  command = [
    "sh", "-c",
    "echo 'Include conf/status.conf' >> /usr/local/apache2/conf/httpd.conf && exec httpd-foreground"
  ]

  upload {
    file    = "/usr/local/apache2/conf/status.conf"
    content = <<-EOT
      ExtendedStatus On
      <Location "/server-status">
        SetHandler server-status
        Require all granted
      </Location>
    EOT
  }

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.red_backend.name
  }
  networks_advanced {
    name = docker_network.red_monitoreo.name
  }

  # Tus archivos web (debe existir volumenes/datos-Apache/index.html)
  volumes {
    host_path      = "${path.cwd}/volumenes/datos-Apache"
    container_path = "/usr/local/apache2/htdocs/"
  }
}

# 4. EXPORTER DE APACHE (traduce /server-status a métricas de Prometheus)
resource "docker_container" "apache_exporter" {
  name  = "contenedor-apache-exporter"
  image = "lusotycoon/apache-exporter:latest"

  command = ["--scrape_uri=http://contenedor-apache/server-status?auto"]

  networks_advanced {
    name = docker_network.red_monitoreo.name
  }

  depends_on = [docker_container.apache]
}

# 5. PROMETHEUS
resource "docker_container" "prometheus" {
  name  = "contenedor-prometheus"
  image = "prom/prometheus:v2.55.1"

  ports {
    internal = 9090
    external = 9090
  }

  networks_advanced {
    name = docker_network.red_monitoreo.name
  }

  volumes {
    host_path      = "${path.cwd}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

# 6. GRAFANA (con el datasource de Prometheus ya configurado)
resource "docker_container" "grafana" {
  name  = "contenedor-grafana"
  image = "grafana/grafana:11.3.0"

  ports {
    internal = 3000
    external = 3000
  }

  networks_advanced {
    name = docker_network.red_monitoreo.name
  }

  upload {
    file    = "/etc/grafana/provisioning/datasources/prometheus.yml"
    content = <<-EOT
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          access: proxy
          url: http://contenedor-prometheus:9090
          isDefault: true
    EOT
  }

  volumes {
    volume_name    = docker_volume.datos_grafana.name
    container_path = "/var/lib/grafana"
  }

  depends_on = [docker_container.prometheus]
}
