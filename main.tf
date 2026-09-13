# =============================================================================
# os-management-k8s-terraform
# Owns the shared network (VPC) + EKS cluster for one environment (develop/main).
# Downstream repos read this state: database (subnets/SG), lambda (subnets/SG),
# app (cluster name/endpoint for kubectl). The app HPA lives in the app repo;
# this stack provides its cluster prerequisite (metrics-server).
# =============================================================================

locals {
  cluster_name = "${var.app_name}-${var.environment}"

  tags = merge({
    Project     = "os-management"
    Component   = "k8s-terraform"
    Environment = var.environment
  }, var.tags)
}

# -----------------------------------------------------------------------------
# VPC — private subnets host EKS nodes + RDS; public subnets host load balancers.
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required for EKS subnet auto-discovery / load balancer placement.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  tags = local.tags
}

# -----------------------------------------------------------------------------
# EKS cluster + managed node group.
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # The CI IAM principal that creates the cluster gets Kubernetes admin.
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      ami_type       = var.node_ami_type
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = max(var.node_desired_size, var.node_min_size)
      subnet_ids     = module.vpc.private_subnets
    }
  }

  tags = local.tags
}

# Auth token for the cluster (used by the helm provider exec fallback name).
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# -----------------------------------------------------------------------------
# metrics-server — required for the app HPA (CPU/memory) to read pod metrics.
# The HPA itself is owned by the app repo and applied with the app manifests.
# -----------------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version
  namespace  = "kube-system"

  # Ensure the cluster + node group exist before installing the chart.
  depends_on = [module.eks]
}
