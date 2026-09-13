terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  # Configured by CI via -backend-config; `terraform init -backend=false` works for validation.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  # Guardrail: fail fast if the active credentials point at an unexpected account.
  # Empty (local validation) = no restriction; CI sets TF_VAR_aws_account_id.
  allowed_account_ids = var.aws_account_id != "" ? [var.aws_account_id] : []

  default_tags {
    tags = {
      Project     = "os-management"
      Component   = "k8s-terraform"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Helm authenticates to the freshly-created EKS cluster using the AWS CLI token
# (exec plugin avoids the 15-minute static-token expiry during long applies).
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.aws_region]
    }
  }
}
