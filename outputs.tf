# =============================================================================
# Network — consumed by os-management-database and os-management-lambda
# (subnets + node SG so RDS/Lambda can sit in the VPC and reach each other).
# =============================================================================
output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS nodes + RDS)."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs (load balancers)."
  value       = module.vpc.public_subnets
}

output "node_security_group_id" {
  description = "Security group of the EKS nodes (opened to RDS on 5432)."
  value       = module.eks.node_security_group_id
}

# =============================================================================
# Cluster — consumed by the app pipeline (aws eks update-kubeconfig) and
# by anything that needs to talk to the Kubernetes API.
# =============================================================================
output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64)."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "region" {
  description = "AWS region the cluster runs in."
  value       = var.aws_region
}
