terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.51.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }

    
  
  backend "azurerm" {

    resource_group_name  = "backend"
    storage_account_name = "oguzhanbackend"
    container_name       = "aksterraformbackend"
    key                  = "terraform.tfstate"
  }
}

# az network nsg rule create --name testrule --nsg-name acceptanceTestSecurityGroup1 --priority 300 --resource-group rg-test --access Allow --destination-port-ranges 30003 --direction Inbound --protocol Tcp
  provider "azurerm" {
  features{}
  }

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "exampleaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
}
data "azurerm_lb" "lb" {
  name                = "kubernetes"
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group #node.rg'nin ismini veriyor
}

data "azurerm_lb_backend_address_pool" "backAP" {
  name            = "kubernetes"
  loadbalancer_id = data.azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "probe3001" {
  loadbalancer_id = data.azurerm_lb.lb.id
  name            = "probe_30001"
  port            = 30001
}

resource "azurerm_lb_probe" "probe3002" {
  loadbalancer_id = data.azurerm_lb.lb.id
  name            = "probe_30002"
  port            = 30002
}

resource "azurerm_lb_rule" "rule1" {
  loadbalancer_id                = data.azurerm_lb.lb.id
  name                           = "rule1"
  protocol                       = "Tcp"
  frontend_port                  = 30001
  backend_port                   = 30001
  frontend_ip_configuration_name = data.azurerm_lb.lb.frontend_ip_configuration.0.name
  disable_outbound_snat          = true
  probe_id                       = azurerm_lb_probe.probe3001.id
  backend_address_pool_ids       = [data.azurerm_lb_backend_address_pool.backAP.id]
}
resource "azurerm_lb_rule" "rule2" {
  loadbalancer_id                = data.azurerm_lb.lb.id
  name                           = "rule2"
  protocol                       = "Tcp"
  frontend_port                  = 30002
  backend_port                   = 30002
  frontend_ip_configuration_name = data.azurerm_lb.lb.frontend_ip_configuration.0.name
  disable_outbound_snat          = true
  probe_id                       = azurerm_lb_probe.probe3002.id

  backend_address_pool_ids = [data.azurerm_lb_backend_address_pool.backAP.id]
}

resource "github_actions_environment_variable" "nodergname_var" {
  repository    = "phonebook_kubernetes"
  variable_name = "NODERG"
  value         = azurerm_kubernetes_cluster.aks.node_resource_group
  environment   = var.environment
}

resource "github_actions_environment_variable" "aksrgname_var" {
  repository    = "phonebook_kubernetes"
  variable_name = "AKSRG_NAME"
  value         = azurerm_resource_group.rg.name
  environment   = var.environment
}

resource "github_actions_environment_variable" "aksname_var" {
  repository    = "phonebook_kubernetes"
  variable_name = "AKS_NAME"
  value         = azurerm_kubernetes_cluster.aks.name
  environment   = var.environment
}

####################
### MYSQL SERVER ###
####################
resource "azurerm_mysql_flexible_server" "db-server" {
  name                   = var.db_server_name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = var.db_username
  administrator_password = var.db_password
  sku_name               = "B_Standard_B1s"
  zone                   = "1"
}

resource "azurerm_mysql_flexible_server_configuration" "require-secure-transport" {
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db-server.name
  value               = "OFF"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow-azure-resources" {
  name                = "AllowAzureResources"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db-server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

######################
### MYSQL DATABASE ###
######################
resource "azurerm_mysql_flexible_database" "db" {
  name                = var.prefix
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.db-server.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}