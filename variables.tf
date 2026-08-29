variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "devops-kubernetes-learning"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version (must be currently supported by AWS)"
  type        = string
  default     = "1.35"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets and node placement"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Root volume size (GiB) for worker nodes"
  type        = number
  default     = 20
}

variable "endpoint_private_access" {
  description = "Whether the EKS API server endpoint is reachable from within the VPC"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server endpoint is publicly reachable"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint (ignored when public access is false)"
  type        = list(string)
  default     = []
}

variable "enable_cluster_log_types" {
  description = "EKS control plane log types to send to CloudWatch (empty = disabled for cost)"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Tags applied to all resources via the AWS provider default_tags"
  type        = map(string)
  default = {
    Project     = "devops-take-home"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
