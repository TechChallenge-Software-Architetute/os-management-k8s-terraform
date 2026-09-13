# =============================================================================
# AWS / environment
# =============================================================================
variable "aws_region" {
  description = "AWS region to deploy the network + cluster into."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Expected AWS account ID. Guards the provider against deploying to the wrong account. Empty = no restriction (local validation)."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deployment environment. Matches the branch name: develop or main."
  type        = string
}

variable "app_name" {
  description = "Base name for resources. Cluster becomes <app_name>-<environment>."
  type        = string
  default     = "os-management"
}

# =============================================================================
# EKS
# =============================================================================
variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane. Must match the cluster's actual current version (check `aws eks describe-cluster`) — EKS auto-upgrades control planes once a version exits Extended Support, and Terraform cannot move the version backward, only one minor version forward per apply."
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group."
  type        = string
  default     = "t3.small"
}

variable "node_ami_type" {
  description = "AMI type for the managed node group. AL2 was retired by EKS on 2025-11-26; use AL2023 (or Bottlerocket) for all supported versions."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_min_size" {
  description = "Minimum number of nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes."
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Desired number of nodes."
  type        = number
  default     = 2
}

# =============================================================================
# VPC
# =============================================================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs for the subnets (minimum 2 for EKS)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  description = "CIDRs for the private subnets (EKS nodes + RDS)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "CIDRs for the public subnets (load balancers)."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cheaper, dev) instead of one per AZ (prod HA)."
  type        = bool
  default     = true
}

# =============================================================================
# metrics-server (cluster prerequisite for the app HPA)
# =============================================================================
variable "metrics_server_chart_version" {
  description = "Version of the metrics-server Helm chart."
  type        = string
  default     = "3.12.2"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
