variable "prefix" {
  default = "phonebook"
}

variable "location" {
  default = "East US"
}

variable "environment" {
  default     = "production"
  description = "production etc."
}

# MySQL Flexible Database
variable "db_server_name" {
  description = "Should be unique and match with the k8s yaml files"
  default     = "oaydogan-phonebook"
  #app.config line 6
}

variable "db_username" {
  description = "Should match with the k8s yaml files"
  default     = "oaydogan"
  #app.config line 8
}

variable "db_password" {
  description = "Should match with the k8s yaml files"
  default     = "Password1234"
  # app.secret line 7
}