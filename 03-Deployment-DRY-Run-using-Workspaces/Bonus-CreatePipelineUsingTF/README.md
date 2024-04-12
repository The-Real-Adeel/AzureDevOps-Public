# Terraform Deployment Summary
Example of how you can create a devops pipeline using terraform


## To run locally on your machine...

### Connect to Azure using AZ CLI
```powershell
az login
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

terraform plan -var "personal_access_token=$personal_access_token" -var "project_name=$project_name" -var "site_url=$site_url" `
               -out tfplan
```

### Terraform Apply

```powershell
terraform apply "tfplan"
```