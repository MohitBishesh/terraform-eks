output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Cluster security group ID"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "node_group_name" {
  description = "Managed node group name"
  value       = aws_eks_node_group.this.node_group_name
}

output "node_role_arn" {
  description = "IAM role ARN used by the managed node group"
  value       = aws_iam_role.node.arn
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for IRSA"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN used by the EBS CSI driver via IRSA"
  value       = aws_iam_role.ebs_csi.arn
}
