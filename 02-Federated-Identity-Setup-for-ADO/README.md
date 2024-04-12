# Terraform Deployment Summary
Goal here is to create a user assigned managed identity that will used as a federated identity in ADO (an improvement over SP as it allows you to operate similar to managed identities outside of your Azure Tenant)

Since this is designed to be the identity for pipelines, we will run this local (chicken and egg problem).

I am going to use the same format as 01-deployment-aks for plan where you have an option to toggle off service principals during plan stage for local runs. Just follow whats written below to get it setup.

As of now this only grants perms to the subscription the managed identity is located in. 03 pipeline will leverage this identity

## Use the pipeline yaml file to deploy using ADO
- Located in Pipeline subdirectory for more information

## To run locally on your machine...

### Connect to Azure using AZ CLI
```powershell
az login # Be sure it has access to backend storage account & is able to deploy as we will omit the service principal from this run
cd "<pathofTFFiles>"
```

### Azure DevOps Az CLI
Since we are interacting with Azure DevOps directly, we need a way to connect to it and retrieve data from it.
You can find details here on how to configure azcli for it: https://learn.microsoft.com/en-us/azure/devops/cli/?view=azure-devops

Set your org and project
```powershell
# az devops configure --list will show you the org and projects set defaults with the following
az devops configure --defaults organization=https://dev.azure.com/<siteName> project=<projectName>
```

### Setup Backend File
Be sure to have a backend.conf file created with the following filled out of where your backend is (Not where you are deploying the resources)
**Note: We are not adding client ID and Client Secret since we dont need them
```
subscription_id       = "<subID>" 
resource_group_name   = "<rgID>
storage_account_name  = "<storageaccountName>"
container_name        = <containername>
key                   =< <keyname> # ie "blobFolderName/terraform.state"
```


### Terraform init
Fill that data in the following stored as variables from the command into the init command and run it to configure the backend
```powershell
terraform init -backend-config="backend.conf"
```

### Terraform plan
Next we will create a plan locally
We have a variable that is used to set using service principal set as false(normally true) so it can null those values as requirements in the azurerm provider. Allowing us to use az login of our account instead of the service principal.
**NOTE: add -destroy flag if you wish to remove these resources

```powershell
# My example is deploying to visual studio enterprise subscription so 
$subscription_id = az account show --subscription "Visual Studio Enterprise Subscription" --query id -o tsv
$tenant_id = az account show --subscription "Visual Studio Enterprise Subscription" --query tenantId -o tsv
$project_name = "<enterName>" # az devops configure --list will show you the project
$site_url = "<EnterURL>" # az devops configure --list will also show you the org URL
$personal_access_token = "<enterPAT>" # NOTE: Personal Access Token can't be created or read using cli. Store its value here

terraform plan -var "subscription_id=$subscription_id" -var "tenant_id=$tenant_id" `
               -var "personal_access_token=$personal_access_token" -var "project_name=$project_name" -var "site_url=$site_url" `
               -var use_service_principal=false -out tfplan #-destroy
```

### Terraform Apply

```powershell
terraform apply "tfplan"
```