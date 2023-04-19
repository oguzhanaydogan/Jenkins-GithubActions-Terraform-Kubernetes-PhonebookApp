variable "prefix" {
  default = ""
}

variable "location" {
  default = ""
}

variable "environment" {
  default = ""
  description = "production etc."
}

# MySQL Flexible Database
variable "db_server_name" {
  description = "Should be unique and match with the k8s yaml files"
  default     = ""
  #app.config line 6
}

variable "db_username" {
  description = "Should match with the k8s yaml files"
  default     = ""
  #app.config line 8
}

variable "db_password" {
  description = "Should match with the k8s yaml files"
  default     = ""
  #app.secret line 7
}