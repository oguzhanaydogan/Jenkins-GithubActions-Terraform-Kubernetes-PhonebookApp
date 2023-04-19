output "NODERG" {
    value = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "AKSRG_NAME" {
  value = azurerm_resource_group.rg.name    
}

output "AKS_NAME" {
value = azurerm_kubernetes_cluster.aks.name 
}

output "MYSQL_HOST" {
    value = azurerm_mysql_flexible_server.db-server.fqdn
  
}
output "MYSQL_PASSWORD" {
    value = var.db_password
}