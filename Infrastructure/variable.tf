variable "name" {
  default = "aks"
}

variable "location" {
  default = "East US"
}

variable "environment" {
  default = "production"
}

variable "prefix" {
  default = "phonebook"
}

# MySQL Flexible Database
variable "db_server_name" {
  description = "Should be unique and match with the Dockerfile"
  default     = "oaydogan-phonebook"
}

variable "db_username" {
  description = "Should match with the Dockerfile"
  default     = "oaydogan"
}

variable "db_password" {
  description = "Should match with the Dockerfile"
  default     = "Password1234"
}

# Container Instance
variable "docker_hub_username" {
  default = "XXX"
}