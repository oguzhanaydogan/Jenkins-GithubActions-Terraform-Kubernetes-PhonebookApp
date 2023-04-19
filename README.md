# Microservice Architecture for Phonebook Web Application (Python Flask) with MySQL using Kubernetes
## Terraform Configuration
The Terraform configuration file deploys the following resources:
- azurerm_resource_group: Creates an Azure resource group named ${var.prefix}-rg in the location ${var.location}.
- azurerm_kubernetes_cluster: Creates an Azure Kubernetes Service cluster named ${var.prefix}-rg in the location ${var.location} with a default node pool containing one node.
- data.azurerm_lb: Retrieves the Azure Load Balancer used by the AKS cluster.
- data.azurerm_lb_backend_address_pool: Retrieves the backend address pool used by the Load Balancer.
- azurerm_lb_probe: Creates two load balancer probes on port 30001 and 30002.
- azurerm_lb_rule: Creates two load balancer rules for ports 30001 and 30002.

To be able to get consistent results for each Terraform apply we need to define a backend to keep our `terraform.tfstate`. We configure our backend to Azure Blob Container with following code
Also to be able to run Terraform file in Jenkins we need to configure code below; 
```
  backend "azurerm" {
    resource_group_name  = "<resource-group-name>"
    storage_account_name = "<storage-account-name>"
    container_name       = "<container-name>"
    key                  = "terraform.tfstate"
    use_msi = true
    subscription_id = "<subscription_id>"
    tenant_id = "<tenant_id>"
  }
  provider "azurerm" {
  features {}
    use_msi = true #we are using managed system identity to connect to Azure account through Jenkins
    subscription_id = "67882e92-6412-4fc5-b9ca-1030aa09d729"
    tenant_id = "1a93b615-8d62-418a-ac28-22501cf1f978"
}
```

To use later in the pipeline we define multiple outputs to use in Jenkins pipeline, code below; 
- `NODERG` = azurerm_kubernetes_cluster.aks.node_resource_group
- `AKSRG_NAME` 
- `AKS_NAME`
- `MYSQL_PASSWORD`
- `MYSQL_HOST`= azurerm_mysql_flexible_server.db-server.fqdn

## Jenkins Configuration

1. Create Infrastructure for the App
This stage creates the infrastructure for the application on the Azure Cloud. It logs in to Azure using the 'az login --identity', changes the working directory to the directory containing the Terraform configuration files, initializes the Terraform project, and applies the Terraform configuration to create the necessary infrastructure.

2. Connect to AKS and Set NSG Permissions
This stage connects to the Kubernetes cluster, injects Terraform output into the connection command, and sets NSG permissions to allow traffic on port 30001-30002.
```
env.AKS_NAME = sh(script: 'terraform output -raw AKS_NAME', returnStdout:true).trim()
env.AKSRG_NAME = sh(script: 'terraform output -raw AKSRG_NAME', returnStdout:true).trim()
env.NODERG = sh(script: 'terraform output -raw NODERG', returnStdout:true).trim()
env.NSG_NAME = sh(script: "az network nsg list --resource-group ${NODERG} --query \"[?contains(name, 'aks')].[name]\" --output tsv", returnStdout:true).trim()
                
sh 'az aks get-credentials --resource-group ${AKSRG_NAME} --name ${AKS_NAME}'
sh 'az network nsg rule create --nsg-name ${NSG_NAME} --resource-group ${NODERG} --name open30001 --access Allow --priority 100 --destination-port-ranges 30001-30002'
```

3. Substitute MySQL Values
This stage substitutes MySQL values in the application configuration and secret files. It injects the MySQL host and password values into the environment variables, echoes the values to the console, and uses envsubst to substitute the values in the configuration and secret templates.
```
sh 'envsubst < ../app-config-template > ../k8s/app-config.yaml'
sh 'envsubst < ../app-secret-template > ../k8s/app-secret.yaml'
```

4. Deploy K8s Files
This stage deploys the Kubernetes files to the Kubernetes cluster. It changes the working directory to the directory containing the Kubernetes files and applies the Kubernetes configuration files using the kubectl command.

5. Destroy the Infrastructure
This stage destroys the infrastructure created in the first stage. It asks for user confirmation before destroying the infrastructure, changes the working directory to the directory containing the Terraform configuration files, and destroys the Terraform project.