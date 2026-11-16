variable "db_root_password" {
  description = "Contraseña root de MariaDB"
  type        = string
  sensitive   = true
  default     = "mi_clave_secreta" # Cámbiala con: terraform apply -var="db_root_password=otra"
}

variable "db_name" {
  description = "Nombre de la base de datos inicial"
  type        = string
  default     = "mi_web_db"
}
variable "db_user" {
  description = "Usuario de la base de datos para la web"
  type        = string
  default     = "web_user"
}

variable "db_password" {
  description = "Contraseña del usuario de la web"
  type        = string
  sensitive   = true
  default     = "web_clave_secreta"
}