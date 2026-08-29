variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and managed node group"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private EKS API endpoint"
  type        = bool
}

variable "endpoint_public_access" {
  description = "Enable public EKS API endpoint"
  type        = bool
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access the public EKS API endpoint"
  type        = list(string)
  default     = []
}

variable "enable_cluster_log_types" {
  description = "Control plane log types to enable"
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired node count"
  type        = number
}

variable "node_min_size" {
  description = "Minimum node count"
  type        = number
}

variable "node_max_size" {
  description = "Maximum node count"
  type        = number
}

variable "node_disk_size" {
  description = "Node root volume size in GiB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
