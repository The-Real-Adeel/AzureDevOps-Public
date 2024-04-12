##########
# Config #
##########

data "azuredevops_project" "ado-project" {
  name = var.project_name
}

data "azuredevops_git_repositories" "repo" {
  project_id = data.azuredevops_project.ado-project.id
  name       = "terraform"
}
# https://techcommunity.microsoft.com/t5/azure-devops-blog/introduction-to-azure-devops-workload-identity-federation-oidc/ba-p/3908687
resource "azuredevops_build_definition" "pipeline" {
  project_id = data.azuredevops_project.ado-project.id
  name       = "Deployment DRY Workspaces" # You can name your pipeline as desired
  repository {
    repo_id   = data.azuredevops_git_repositories.repo.repositories[0].id
    repo_type = "TfsGit"
    yml_path  = "03-Deployment-DRY-Run-using-Workspaces/Pipeline/azure-pipelines.yml"
    branch_name = "main"
  }
}

