pipeline {
    agent any
    tools {
        terraform 'terraform'
    }

    stages {
        stage('Create Infrastructure for the App') {
            steps {
                sh 'az login --identity'
                dir('/var/lib/jenkins/workspace/PHONEBOOK-KUBERNETES/Infrastructure-jenkins'){
                    echo 'Creating Infrastructure for the App on AZURE Cloud'
                    sh 'terraform init'
                    sh 'terraform apply --auto-approve'
                }
            }
        }

        stage('Connect to AKS and set NSG permissions') {
            steps {
                dir('/var/lib/jenkins/workspace/PHONEBOOK-KUBERNETES/Infrastructure-jenkins'){
                    echo 'Injecting Terraform Output into connection command'
                    script {
                        env.AKS_NAME = sh(script: 'terraform output -raw AKS_NAME', returnStdout:true).trim()
                        env.AKSRG_NAME = sh(script: 'terraform output -raw AKSRG_NAME', returnStdout:true).trim()
                        env.NODERG = sh(script: 'terraform output -raw NODERG', returnStdout:true).trim()
                        env.NSG_NAME = sh(script: "az network nsg list --resource-group ${NODERG} --query \"[?contains(name, 'aks')].[name]\" --output tsv", returnStdout:true).trim()
                    }
                    sh 'az aks get-credentials --resource-group ${AKSRG_NAME} --name ${AKS_NAME}'
                    sh 'az network nsg rule create --nsg-name ${NSG_NAME} --resource-group ${NODERG} --name open30001 --access Allow --priority 100 --destination-port-ranges 30001-30002'
                        



                }
            }
        }
        stage('Substitute mysql values') {
            steps {
              dir('/var/lib/jenkins/workspace/PHONEBOOK-KUBERNETES/Infrastructure-jenkins'){
                echo 'Substitute mysql values'
                script {
                    env.MYSQL_HOST = sh(script: 'terraform output -raw MYSQL_HOST', returnStdout:true).trim()
                    env.MYSQL_PASSWORD = sh(script: 'terraform output -raw MYSQL_PASSWORD', returnStdout:true).trim()
                }
                sh 'echo ${MYSQL_HOST}'
                sh 'echo ${MYSQL_PASSWORD}'
                sh 'envsubst < app-config-template > ./k8s/app-config.yaml'
                sh 'cat ./k8s/app-config.yaml'
                sh 'envsubst < app-secret-template > ./k8s/app-secret.yaml'
                sh 'cat ./k8s/app-secret.yaml'
              }
            }
        }
        stage('Deploy K8s files') {
            steps {
                dir('/var/lib/jenkins/workspace/PHONEBOOK-KUBERNETES/k8s') {
                    sh 'kubectl apply -f .'
                }
            }
        }
        stage('Destroy the Infrastructure') {
            steps{
                timeout(time:5, unit:'DAYS'){
                    input message:'Do you want to terminate?'
                }
                dir('/var/lib/jenkins/workspace/PHONEBOOK-KUBERNETES/Infrastructure-jenkins'){
                    sh """
                    terraform destroy --auto-approve
                    """
                }
            }
        }
    }
}