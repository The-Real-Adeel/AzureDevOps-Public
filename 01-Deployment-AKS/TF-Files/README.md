# Terraform Deployment Summary
- Deploy AKS Cluster using terraform. This deployment is more for deploying a pipeline than whats inside the TF files. 
- The deployment is a simple AKS cluster that uses managed identities.
- it includes doing the deployment stage work for workload identities (which will be assigned later once you have namespaces and service accounts in AKS)
- Eventual goal is to expand this deployment pipelane to have a second phase that sets up the AKS with crossplane using these services.
- It still uses ADO agents and service principals for AuthN to Azure. This will be addressed in the future as well. You dont need to run the files in 00 before doing this one.

## Use the pipeline yaml file to deploy using ADO
- Located in Pipeline subdirectory for more information

## To run locally on your machine...

### Connect to Azure using AZ Cli
```powershell
az login # Be sure it has access to backend storage account & is able to deploy as we will omit the service principal from this run
cd "<pathofTFFiles>"
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
terraform plan -var "subscription_id=$subscription_id" -var "tenant_id=$tenant_id" -var use_service_principal=false -out tfplan #-destroy
```

### Terraform Apply

```powershell
terraform apply "tfplan"
```