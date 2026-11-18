# Renommé en backend.tf APRÈS la première création du socle (voir ROADMAP, étape 9)
terraform {
  backend "s3" {
    bucket       = "tfstate-armelcloudops-gitops"
    key          = "socle/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
