# Phase-1: VPC + EKS only.
#
# Cost/availability trade-offs (intentional for this take-home):
# - 2 AZs instead of 3
# - Single NAT Gateway (both private subnets share it) — AZ failure of the NAT AZ
#   breaks private egress until recovery; halves NAT cost vs per-AZ NAT
# - t3.medium workers, desired/min 2, max 3
# - Private worker nodes (no public IPs); egress via NAT
# - Managed node group (simpler than self-managed / Karpenter)
# - Cluster control-plane logging off by default (CloudWatch cost)
# - No ALB/NLB, no VPC interface endpoints, no non-essential add-ons yet

locals {
  # Validate AZ / subnet CIDR alignment early
  az_count = length(var.availability_zones)
}

check "az_subnet_alignment" {
  assert {
    condition = (
      length(var.public_subnet_cidrs) == local.az_count &&
      length(var.private_subnet_cidrs) == local.az_count
    )
    error_message = "public_subnet_cidrs and private_subnet_cidrs must each match availability_zones length."
  }
}

check "public_endpoint_cidrs" {
  assert {
    condition = (
      !var.endpoint_public_access ||
      (length(var.public_access_cidrs) > 0 && !contains(var.public_access_cidrs, "0.0.0.0/0"))
    )
    error_message = "When endpoint_public_access is true, set public_access_cidrs to specific CIDRs (not 0.0.0.0/0)."
  }
}

module "vpc" {
  source = "./modules/vpc"

  name                 = var.cluster_name
  cidr                 = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = var.cluster_name
  tags                 = var.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name             = var.cluster_name
  cluster_version          = var.kubernetes_version
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  endpoint_private_access  = var.endpoint_private_access
  endpoint_public_access   = var.endpoint_public_access
  public_access_cidrs      = var.public_access_cidrs
  enable_cluster_log_types = var.enable_cluster_log_types
  node_instance_types      = var.node_instance_types
  node_desired_size        = var.node_desired_size
  node_min_size            = var.node_min_size
  node_max_size            = var.node_max_size
  node_disk_size           = var.node_disk_size
  tags                     = var.common_tags
}
