terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.51.0"
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
  features {}
}

resource "azurerm_resource_group" "rg1" {
  name     = "rg-test"
  location = "EAST US"
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  dns_prefix          = "exampleaks1"

  network_profile {
    network_plugin = "azure"
    dns_service_ip = "10.2.0.10"
    service_cidr   = "10.2.0.0/24"
  }

  depends_on = [
    azurerm_network_security_group.nsg
  ]

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.example.id
  }

  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_lb" "lb" {
  name                = "Kubernetes"
  resource_group_name = azurerm_kubernetes_cluster.example.node_resource_group
}

data "azurerm_lb_backend_address_pool" "lb_bap" {
  name            = "kubernetes"
  loadbalancer_id = data.azurerm_lb.lb.id
}

resource "azurerm_lb_rule" "lb_rule1" {
  loadbalancer_id                = data.azurerm_lb.lb.id
  name                           = "LBRule1"
  protocol                       = "Tcp"
  frontend_port                  = 30001
  backend_port                   = 30001
  frontend_ip_configuration_name = data.azurerm_lb.lb.frontend_ip_configuration.0.name
  backend_address_pool_ids       = [data.azurerm_lb_backend_address_pool.lb_bap.id]
  disable_outbound_snat          = true
  probe_id                       = azurerm_lb_probe.lb_probe1.id
}

resource "azurerm_lb_rule" "lb_rule2" {
  loadbalancer_id                = data.azurerm_lb.lb.id
  name                           = "LBRule2"
  protocol                       = "Tcp"
  frontend_port                  = 30002
  backend_port                   = 30002
  frontend_ip_configuration_name = data.azurerm_lb.lb.frontend_ip_configuration.0.name
  backend_address_pool_ids       = [data.azurerm_lb_backend_address_pool.lb_bap.id]
  disable_outbound_snat          = true
  probe_id                       = azurerm_lb_probe.lb_probe2.id
}

resource "azurerm_lb_probe" "lb_probe1" {
  loadbalancer_id = data.azurerm_lb.lb.id
  name            = "probe1"
  port            = 30001
}

resource "azurerm_lb_probe" "lb_probe2" {
  loadbalancer_id = data.azurerm_lb.lb.id
  name            = "probe2"
  port            = 30002
}

resource "azurerm_virtual_network" "vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30001-30002"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}