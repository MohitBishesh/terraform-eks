output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS worker subnets)"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "Single NAT Gateway ID (cost-optimized; shared by both private AZs)"
  value       = module.vpc.nat_gateway_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Cluster security group ID created by EKS"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_group_name" {
  description = "Managed node group name"
  value       = module.eks.node_group_name
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN (for IRSA in later phases)"
  value       = module.eks.oidc_provider_arn
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA certificate (for kubeconfig)"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "configure_kubectl" {
  description = "Command to update kubeconfig after apply (requires network path to the API endpoint)"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
